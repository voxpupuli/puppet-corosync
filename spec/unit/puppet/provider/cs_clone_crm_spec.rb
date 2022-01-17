# frozen_string_literal: true
require 'spec_helper'

describe Puppet::Type.type(:cs_clone).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
  end

  context 'when getting instances with primitive' do
    let :instances do
      test_cib = <<-EOS
        <cib>
        <configuration>
          <resources>
            <clone id="p_keystone-clone">
              <primitive class="systemd" id="p_keystone" type="openstack-keystone">
                <meta_attributes id="p_keystone-meta_attributes"/>
                <operations/>
              </primitive>
              <meta_attributes id="p_keystone-clone-meta"/>
            </clone>
          </resources>
        </configuration>
        </cib>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      Puppet::Util::Execution.expects(:execute).with(%w[crm configure show xml], combine: true, failonfail: true).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
      )
      described_class.instances
    end

    it 'has an instance for each <clone>' do
      expect(instances.count).to eq(1)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "is named by the <primitive>'s id attribute" do
        expect(instance.name).to eq('p_keystone-clone')
      end

      it 'has the correct primitive property' do
        expect(instance.primitive).to eq('p_keystone')
      end

      it 'has no group property' do
        expect(instance.group).to eq(:absent)
      end
    end
  end

  context 'when getting instances with group' do
    let :instances do
      test_cib = <<-EOS
        <cib>
        <configuration>
          <resources>
            <clone id="duncan_vip_clone_group">
              <group id="duncan_group">
                <primitive id="duncan_vip2" class="ocf" provider="heartbeat" type="IPaddr2">
                  <operations>
                    <op name="monitor" interval="10s" id="duncan_vip2-monitor-10s"/>
                  </operations>
                  <instance_attributes id="duncan_vip2-instance_attributes">
                    <nvpair name="ip" value="172.16.210.102" id="duncan_vip2-instance_attributes-ip"/>
                    <nvpair name="cidr_netmask" value="24" id="duncan_vip2-instance_attributes-cidr_netmask"/>
                  </instance_attributes>
                </primitive>
              </group>
            </clone>
          </resources>
        </configuration>
        </cib>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      Puppet::Util::Execution.expects(:execute).with(%w[crm configure show xml], combine: true, failonfail: true).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
      )
      described_class.instances
    end

    it 'has an instance for each <clone>' do
      expect(instances.count).to eq(1)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      before do
        instance.stubs(:change_clone_id) { nil }
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "is named by the <primitive>'s id attribute" do
        expect(instance.name).to eq('duncan_vip_clone_group')
      end

      it 'has the correct group property' do
        expect(instance.group).to eq('duncan_group')
      end

      it 'has no primitive property' do
        expect(instance.primitive).to eq(:absent)
      end
    end
  end

  context 'when flushing' do
    def expect_update(pattern)
      if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
        Puppet::Util::SUIDManager.expects(:run_and_capture).with do |*args|
          expect(File.read(args[3])).to match(pattern) if args.slice(0..2) == %w[configure load update]
          true
        end.at_least_once.returns(['', 0])
      else
        Puppet::Util::Execution.expects(:execute).with do |*args|
          expect(File.read(args[3])).to match(pattern) if args.slice(0..2) == %w[configure load update]
          true
        end.at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new('', 0)
        )
      end
    end

    let :resource do
      Puppet::Type.type(:cs_clone).new(
        name: 'p_keystone-clone',
        provider: :crm,
        primitive: 'p_keystone',
        ensure: :present
      )
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    it 'creates clone' do
      expect_update(%r{clone p_keystone-clone p_keystone})
      instance.flush
    end

    it 'sets max clones' do
      instance.resource[:clone_max] = 3
      expect_update(%r{\sclone-max=3})
      instance.flush
    end

    it 'sets max node clones' do
      instance.resource[:clone_node_max] = 3
      expect_update(%r{\sclone-node-max=3})
      instance.flush
    end

    it 'sets notify_clones' do
      instance.resource[:notify_clones] = :true
      expect_update(%r{\snotify=true})
      instance.flush
    end

    it 'sets globally unique' do
      instance.resource[:globally_unique] = :true
      expect_update(%r{\sglobally-unique=true})
      instance.flush
    end

    it 'sets ordered' do
      instance.resource[:ordered] = :true
      expect_update(%r{\sordered=true})
      instance.flush
    end

    it 'sets interleave' do
      instance.resource[:interleave] = :true
      expect_update(%r{\sinterleave=true})
      instance.flush
    end
  end
end
