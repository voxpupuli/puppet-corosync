require 'spec_helper'
require 'spec_helper_corosync'

describe Puppet::Type.type(:cs_clone).provider(:pcs) do
  include_context 'pcs'

  context 'when getting instances' do
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
    end
  end

  context 'when flushing' do
    let :resource do
      Puppet::Type.type(:cs_clone).new(
        name:      'p_keystone-clone',
        primitive: 'p_keystone',
        provider:  :pcs,
        ensure:    :present
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
      instance.clone_max = 3
      expect_commands(%r{clone-max=3})
      instance.flush
    end

    it 'sets max node clones' do
      instance.clone_node_max = 3
      expect_commands(%r{clone-node-max=3})
      instance.flush
    end

    it 'sets notify_clones' do
      instance.notify_clones = :true
      expect_commands(%r{notify=true})
      instance.flush
    end

    it 'sets globally unique' do
      instance.globally_unique = :true
      expect_commands(%r{globally-unique=true})
      instance.flush
    end

    it 'sets ordered' do
      instance.ordered = :true
      expect_commands(%r{ordered=true})
      instance.flush
    end

    it 'sets interleave' do
      instance.interleave = :true
      expect_commands(%r{interleave=true})
      instance.flush
    end
  end

  context 'when changing clone id' do
    def clone_xml(name)
      <<-EOS
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
        instance.change_clone_id('apache_service', 'apache_service-newclone', nil)
      end

      it 'calls cibadmin only when needed' do
        xpath = '/cib/configuration/resources/clone[descendant::primitive[@id=\'apache_service\']]'
        Puppet::Util::Execution.expects(:execute).with(['cibadmin', '--query', '--xpath', xpath], failonfail: true, combine: true).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(clone_xml('apache_service-clone'), 0)
        )
        instance.change_clone_id('apache_service', 'apache_service-clone', nil)
      end
    end
  end
end
