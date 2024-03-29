# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:cs_rsc_defaults).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
  end

  context 'when getting instances' do
    let :instances do
      test_cib = <<-EOS
        <cib>
          <configuration>
            <rsc_defaults>
              <meta_attributes id="rsc-options">
                <nvpair id="rsc-options-resource-stickiness" name="resource-stickiness" value="INFINITY"/>
                <nvpair id="rsc-options-migration-threshold" name="migration-threshold" value="1"/>
              </meta_attributes>
            </rsc_defaults>
          </configuration>
        </cib>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      Puppet::Util::Execution.expects(:execute).with(%w[crm configure show xml], combine: true, failonfail: true).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
      )
      described_class.instances
    end

    it 'has an instance for each <nvpair> in <cluster_property_set>' do
      expect(instances.count).to eq(2)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a(described_class)
      end

      it "is named by the <nvpair>'s name attribute" do
        expect(instance.name).to eq('resource-stickiness')
      end

      it "has a value corresponding to the <nvpair>'s value attribute" do
        expect(instance.value).to eq('INFINITY')
      end
    end
  end
end
