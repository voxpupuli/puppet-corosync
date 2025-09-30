# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:cs_colocation).provider(:pcs)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:cs_colocation).new(
      name: 'colo1',
      primitives: %w[resA resB],
      score: 'INFINITY'
    )
  end

  let(:provider) { provider_class.new(resource) }

  before do
    allow(provider_class).to receive(:command).with(:pcs).and_return('pcs')
  end

  describe '.instances' do
    let(:xml) do
      <<-XML
      <cib>
        <configuration>
          <constraints>
            <rsc_colocation id="colo1" rsc="resA" with-rsc="resB" score="INFINITY"/>
            <rsc_colocation id="colo2" score="200">
              <resource_set sequential="true">
                <resource_ref id="resC"/>
                <resource_ref id="resD"/>
              </resource_set>
            </rsc_colocation>
          </constraints>
        </configuration>
      </cib>
      XML
    end

    before do
      allow(provider_class).to receive(:block_until_ready)
      allow(provider_class).to receive(:run_command_in_cib).and_return([xml, 0])
    end

    it 'parses simple colocations' do
      instances = provider_class.instances
      colo = instances.find { |i| i.name == 'colo1' }
      expect(colo).not_to be_nil
      expect(colo.primitives).to be == %w[resB resA]
      expect(colo.score).to be == 'INFINITY'
    end

    it 'parses colocations with resource sets' do
      instances = provider_class.instances
      colo = instances.find { |i| i.name == 'colo2' }
      expect(colo.primitives.first['primitives']).to be == %w[resC resD]
      expect(colo.score).to be == '200'
    end
  end

  describe '.instances with with-rsc-role' do
    def cib_with_role(role)
      <<-XML
      <cib>
        <configuration>
          <constraints>
            <rsc_colocation id="colo_#{role}" rsc="resA" with-rsc="resB" with-rsc-role="#{role}" score="100"/>
          </constraints>
        </configuration>
      </cib>
      XML
    end

    before do
      allow(provider_class).to receive(:block_until_ready)
    end

    it 'maps Promoted to :Master' do
      allow(provider_class).to receive(:run_command_in_cib).and_return([cib_with_role('Promoted'), 0])
      colo = provider_class.instances.find { |i| i.name == 'colo_Promoted' }
      expect(colo.primitives).to be == %w[resB:Master resA]
    end

    it 'maps Unpromoted to :Slave' do
      allow(provider_class).to receive(:run_command_in_cib).and_return([cib_with_role('Unpromoted'), 0])
      colo = provider_class.instances.find { |i| i.name == 'colo_Unpromoted' }
      expect(colo.primitives).to be == %w[resB:Slave resA]
    end

    it 'keeps Started without suffix' do
      allow(provider_class).to receive(:run_command_in_cib).and_return([cib_with_role('Started'), 0])
      colo = provider_class.instances.find { |i| i.name == 'colo_Started' }
      expect(colo.primitives).to be == %w[resB resA]
    end

    it 'maps arbitrary role to custom suffix' do
      allow(provider_class).to receive(:run_command_in_cib).and_return([cib_with_role('Stopped'), 0])
      colo = provider_class.instances.find { |i| i.name == 'colo_Stopped' }
      expect(colo.primitives).to be == %w[resB:Stopped resA]
    end
  end

  describe '#create' do
    it 'populates property_hash with new=true' do
      provider.create
      expect(provider.instance_variable_get(:@property_hash)[:new]).to be true
    end
  end

  describe '#destroy' do
    it 'calls pcs constraint remove' do
      allow(provider_class).to receive(:run_command_in_cib)
      provider.destroy
      expect(provider_class).to have_received(:run_command_in_cib).
        with(%w[pcs constraint remove colo1], nil)
    end
  end

  describe '#format_resource_set' do
    it 'formats hash into array' do
      rs = { 'sequential' => 'true', 'action' => 'promote' }
      expect(provider.format_resource_set(rs)).to include('sequential=true', 'action=promote')
    end

    it 'formats array into array' do
      rs = %w[resA resB]
      expect(provider.format_resource_set(rs.dup)).to be == %w[resA resB]
    end
  end

  describe '#flush' do
    before do
      provider.instance_variable_set(
        :@property_hash,
        {
          name: 'colo1',
          ensure: :present,
          primitives: %w[resA resB],
          score: 'INFINITY',
          new: true
        }
      )
      allow(provider_class).to receive(:run_command_in_cib)
    end

    it 'adds a colocation with pcs' do
      provider.flush
      expect(provider_class).to have_received(:run_command_in_cib).
        with(array_including('pcs', 'constraint', 'colocation', 'add'), nil)
    end
  end
end
