require 'spec_helper'
require 'spec_helper_corosync'

describe Puppet::Type.type(:cs_clone).provider(:pcs) do
  include_context 'pcs'

  context 'when getting instances with primitive' do
    let :instances do
      cib = <<-EOS
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

      pcs_load_cib(cib)
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
      cib = <<-EOS
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

      pcs_load_cib(cib)
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
    let :resource do
      Puppet::Type.type(:cs_clone).new(
        name: 'p_keystone-clone',
        primitive: 'p_keystone',
        provider: :pcs,
        ensure: :present
      )
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    before do
      instance.stubs(:change_clone_id) { nil }
    end

    it 'creates clone' do
      expect_commands(%r{pcs resource clone p_keystone})
      instance.flush
    end

    it 'sets max clones' do
      instance.resource[:clone_max] = 3
      expect_commands(%r{clone-max=3})
      instance.flush
    end

    it 'sets max node clones' do
      instance.resource[:clone_node_max] = 3
      expect_commands(%r{clone-node-max=3})
      instance.flush
    end

    it 'sets notify_clones' do
      instance.resource[:notify_clones] = :true
      expect_commands(%r{notify=true})
      instance.flush
    end

    it 'sets globally unique' do
      instance.resource[:globally_unique] = :true
      expect_commands(%r{globally-unique=true})
      instance.flush
    end

    it 'sets ordered' do
      instance.resource[:ordered] = :true
      expect_commands(%r{ordered=true})
      instance.flush
    end

    it 'sets interleave' do
      instance.resource[:interleave] = :true
      expect_commands(%r{interleave=true})
      instance.flush
    end
  end

  context 'when changing clone id' do
    def clone_xml(name)
      <<~EOS
        <clone id='#{name}'>
          <primitive class='ocf' id='apache_service' provider='heartbeat' type='IPaddr2'>
            <instance_attributes id='apache_service-instance_attributes'>
              <nvpair id='apache_service-instance_attributes-ip' name='ip' value='172.16.210.101'/>
              <nvpair id='apache_service-instance_attributes-cidr_netmask' name='cidr_netmask' value='24'/>
            </instance_attributes>
            <operations>
              <op id='apache_service-monitor-interval-10s' interval='10s' name='monitor'/>
            </operations>
          </primitive>
          <meta_attributes id='apache_service-clone-meta_attributes'/>
        </clone>
      EOS
    end

    let :instances do
      cib = <<-EOS
        <cib>
        <configuration>
          <resources>
      #{clone_xml('apache_service-clone')}
          </resources>
        </configuration>
        </cib>
      EOS

      pcs_load_cib(cib)
      described_class.instances
    end

    it 'has an instance for each <clone>' do
      expect(instances.count).to eq(1)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it 'calls cibadmin with the correct parameters' do
        xpath = '/cib/configuration/resources/clone[descendant::primitive[@id=\'apache_service\']]'
        Puppet::Util::Execution.expects(:execute).with(['cibadmin', '--query', '--xpath', xpath], failonfail: true, combine: true).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(clone_xml('apache_service-clone'), 0)
        )
        Puppet::Util::Execution.expects(:execute).with(['cibadmin', '--replace', '--xpath', xpath, '--xml-text', clone_xml('apache_service-newclone').chop], failonfail: true, combine: true).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new('', 0)
        )
        instance.change_clone_id('primitive', 'apache_service', 'apache_service-newclone', nil)
      end

      it 'calls cibadmin only when needed' do
        xpath = '/cib/configuration/resources/clone[descendant::primitive[@id=\'apache_service\']]'
        Puppet::Util::Execution.expects(:execute).with(['cibadmin', '--query', '--xpath', xpath], failonfail: true, combine: true).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(clone_xml('apache_service-clone'), 0)
        )
        instance.change_clone_id('primitive', 'apache_service', 'apache_service-clone', nil)
      end
    end
  end
end
