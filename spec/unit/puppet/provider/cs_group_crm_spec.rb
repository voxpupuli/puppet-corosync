require 'spec_helper'

describe Puppet::Type.type(:cs_group).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
  end

  let :instances do
    cib = <<-EOS
      <cib>
      <configuration>
        <resources>
          <group id="duncan_group">
            <primitive id="duncan_vip1" class="ocf" provider="heartbeat" type="IPaddr2">
              <operations>
                <op name="monitor" interval="10s" id="duncan_vip2-monitor-10s"/>
              </operations>
              <instance_attributes id="duncan_vip2-instance_attributes">
                <nvpair name="ip" value="172.16.210.102" id="duncan_vip2-instance_attributes-ip"/>
                <nvpair name="cidr_netmask" value="24" id="duncan_vip2-instance_attributes-cidr_netmask"/>
              </instance_attributes>
            </primitive>
          </group>
          <clone id="clone">
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
              <primitive id="duncan_vip3" class="ocf" provider="heartbeat" type="IPaddr2">
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
    Puppet::Util::Execution.expects(:execute).with(%w[crm configure show xml], failonfail: true, combine: true).at_least_once.returns(
      Puppet::Util::Execution::ProcessOutput.new(cib, 0)
    )
    described_class.instances
  end

  context 'when getting instances' do
    it 'has an instance for each group' do
      expect(instances.count).to eq(2)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it 'is named by the group id attribute' do
        expect(instance.name).to eq('duncan_group')
      end
    end

    describe 'first instance' do
      let :instance do
        instances.first
      end

      it 'has primitives equal to duncan_vip1' do
        expect(instance.primitives).to eq(['duncan_vip1'])
      end
    end

    describe 'second instance' do
      let :instance do
        instances[1]
      end

      it 'has primitives equal to duncan_vip2 and duncan_vip3' do
        expect(instance.primitives).to eq(%w[duncan_vip2 duncan_vip3])
      end
    end
  end
end
