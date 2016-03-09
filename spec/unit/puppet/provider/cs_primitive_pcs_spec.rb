require 'spec_helper'
require 'spec_helper_corosync'

describe Puppet::Type.type(:cs_primitive).provider(:pcs) do
  before do
    described_class.stubs(:command).with(:pcs).returns 'pcs'
  end

  context 'when getting instances' do
    let :instances do
      test_cib = <<-EOS
        <configuration>
          <resources>
            <primitive class="ocf" id="example_vm" provider="heartbeat" type="Xen">
              <instance_attributes id="example_vm-instance_attributes">
                <nvpair id="example_vm-instance_attributes-xmfile" name="xmfile" value="/etc/xen/example_vm.cfg"/>
                <nvpair id="example_vm-instance_attributes-name" name="name" value="example_vm_name"/>
              </instance_attributes>
              <utilization id="example_vm-utilization">
                <nvpair id="example_vm-utilization-ram" name="ram" value="256"/>
              </utilization>
              <meta_attributes id="example_vm-meta_attributes">
                <nvpair id="example_vm-meta_attributes-target-role" name="target-role" value="Started"/>
                <nvpair id="example_vm-meta_attributes-priority" name="priority" value="7"/>
              </meta_attributes>
              <operations>
                <op id="example_vm-start-0" interval="0" name="start" timeout="60"/>
                <op id="example_vm-stop-0" interval="0" name="stop" timeout="40"/>
              </operations>
            </primitive>
          </resources>
        </configuration>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(%w(pcs cluster cib)).at_least_once.returns([test_cib, 0])
      else
        Puppet::Util::Execution.expects(:execute).with(%w(pcs cluster cib), :failonfail => true, :combine => true).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
        )
      end
      # rubocop:disable Lint/UselessAssignment
      instances = described_class.instances
      # rubocop:enable Lint/UselessAssignment
    end

    it 'should have an instance for each <primitive>' do
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
        expect(instance.name).to eq(:example_vm)
      end

      it 'has a parameters property corresponding to <instance_attributes>' do
        expect(instance.parameters).to eq('xmfile' => '/etc/xen/example_vm.cfg',
                                          'name' => 'example_vm_name')
      end

      it 'has an operations property corresponding to <operations>' do
        expect(instance.operations).to match_array([{ 'start' => { 'interval' => '0', 'timeout' => '60' } },
                                                    { 'stop'  => { 'interval' => '0', 'timeout' => '40' } }])
      end

      it 'has a utilization property corresponding to <utilization>' do
        expect(instance.utilization).to eq('ram' => '256')
      end

      it 'has a metadata property corresponding to <meta_attributes>' do
        expect(instance.metadata).to eq('target-role' => 'Started',
                                        'priority' => '7')
      end

      it 'has an ms_metadata property' do
        expect(instance).to respond_to(:ms_metadata)
      end

      it 'has a promotable property that is :false' do
        expect(instance.promotable).to eq(:false)
      end
    end
  end

  context 'when flushing' do
    let :instances do
      test_cib = <<-EOS
        <configuration>
          <resources>
            <primitive class="ocf" id="simple" provider="heartbeat" type="IPaddr2" />
            <primitive class="ocf" id="example_vip" provider="heartbeat" type="IPaddr2">
              <operations>
                <op id="example_vip-monitor-10s" interval="10s" name="monitor"/>
              </operations>
              <instance_attributes id="example_vip-instance_attributes">
                <nvpair id="example_vip-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
                <nvpair id="example_vip-instance_attributes-ip" name="ip" value="172.31.110.68"/>
              </instance_attributes>
            </primitive>
h           <primitive class="ocf" id="example_vip_with_op" provider="heartbeat" type="IPaddr2">
              <operations>
                <op id="example_vip-monitor-10s" interval="10s" name="monitor"/>
                <op id="example_vip-monitor-10s" interval="20s" name="monitor2"/>
                <op id="example_vip-monitor-10s" interval="30s" name="monitor3"/>
              </operations>
              <instance_attributes id="example_vip-instance_attributes">
                <nvpair id="example_vip-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
                <nvpair id="example_vip-instance_attributes-ip" name="ip" value="172.31.110.68"/>
              </instance_attributes>
            </primitive>
          </resources>
        </configuration>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(%w(pcs cluster cib)).at_least_once.returns([test_cib, 0])
      else
        Puppet::Util::Execution.expects(:execute).with(%w(pcs cluster cib), :failonfail => true, :combine => true).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
        )
      end
      # rubocop:disable Lint/UselessAssignment
      instances = described_class.instances
      # rubocop:enable Lint/UselessAssignment
    end

    let :prefetch do
      described_class.prefetch
    end

    let :resource do
      Puppet::Type.type(:cs_primitive).new(
        :name => 'testResource',
        :provider => :pcs,
        :primitive_class => 'ocf',
        :provided_by => 'heartbeat',
        :operations => { 'monitor' => { 'interval' => '60s' } },
        :primitive_type => 'IPaddr2')
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    let :simple_instance do
      instances.first
    end

    let :vip_instance do
      instances[1]
    end

    let :vip_op_instance do
      instances[2]
    end

    it 'can flush without changes' do
      expect_commands(/pcs/)
      simple_instance.flush
    end

    it 'sets operations' do
      instance.operations = [{ 'monitor' => { 'interval' => '20s' } }]
      expect_commands([
                        /^pcs resource create --force testResource ocf:heartbeat:IPaddr2 op monitor interval=20s$/,
                        /^pcs resource op remove testResource monitor interval=60s$/
                      ])
      instance.flush
    end

    it 'do not remove default operations if explicitely set' do
      instance.operations = [{ 'monitor' => { 'interval' => '60s' } }]
      expect_commands(/^pcs resource create --force testResource ocf:heartbeat:IPaddr2 op monitor interval=60s$/)
      instance.flush
    end

    it 'sets utilization' do
      instance.utilization = { 'waffles' => '5' }
      expect_commands(/^pcs resource create --force testResource ocf:heartbeat:IPaddr2 op .* utilization waffles=5$/)
      instance.flush
    end

    it 'sets parameters' do
      instance.parameters = { 'fluffyness' => '12' }
      expect_commands(/^pcs resource create --force testResource ocf:heartbeat:IPaddr2 fluffyness=12 op.*/)
      instance.flush
    end

    it 'sets metadata' do
      instance.metadata = { 'target-role' => 'Started' }
      expect_commands(/^pcs resource create --force testResource ocf:heartbeat:IPaddr2 op .* meta target-role=Started$/)
      instance.flush
    end

    it 'sets the primitive name and type' do
      expect_commands(/^pcs resource create --force testResource ocf:heartbeat:IPaddr2/)
      instance.flush
    end

    it 'update operations without changing operations that are already there' do
      vip_op_instance.operations = [
        { 'monitor' => { 'interval' => '20s' } },
        { 'monitor2' => { 'interval' => '20s' } }
      ]
      expect_commands([
                        /^pcs resource op remove example_vip_with_op monitor interval=10s$/,
                        /^pcs resource op remove example_vip_with_op monitor3 interval=30s$/,
                        /^pcs resource update example_vip_with_op cidr_netmask=24 ip=172.31.110.68 op monitor interval=20s op monitor2 interval=20s/
                      ])
      vip_op_instance.flush
    end

    it "sets a primitive_class parameter corresponding to the <primitive>'s class attribute" do
      vip_instance.primitive_class = 'stonith'
      expect_commands([
                        /^pcs resource unclone example_vip$/,
                        /^pcs resource delete --force example_vip$/,
                        /^pcs resource create --force example_vip stonith:heartbeat:IPaddr2/,
                        /^pcs resource op remove example_vip monitor interval=60s$/
                      ])
      vip_instance.flush
    end

    it "sets a provided_by parameter corresponding to the <primitive>'s class attribute" do
      vip_instance.provided_by = 'voxpupuli'
      expect_commands([
                        /^pcs resource unclone example_vip$/,
                        /^pcs resource delete --force example_vip$/,
                        /^pcs resource create --force example_vip ocf:voxpupuli:IPaddr2/,
                        /^pcs resource op remove example_vip monitor interval=60s$/
                      ])
      vip_instance.flush
    end

    it "sets an primitive_type parameter corresponding to the <primitive>'s type attribute" do
      vip_instance.primitive_type = 'IPaddr3'
      expect_commands([
                        /^pcs resource unclone example_vip$/,
                        /^pcs resource delete --force example_vip$/,
                        /^pcs resource create --force example_vip ocf:heartbeat:IPaddr3/,
                        /^pcs resource op remove example_vip monitor interval=60s$/
                      ])
      vip_instance.flush
    end

    it 'creates a primitive without provided_by parameter' do
      vip_instance.primitive_class = 'systemd'
      vip_instance.provided_by = nil
      vip_instance.primitive_type = 'httpd'
      expect_commands([
                        /^pcs resource unclone example_vip$/,
                        /^pcs resource delete --force example_vip$/,
                        /^pcs resource create --force example_vip systemd:httpd/,
                        /^pcs resource op remove example_vip monitor interval=60s$/
                      ])
      vip_instance.flush
    end

    it "sets an provided_by parameter corresponding to the <primitive>'s provider attribute" do
      vip_instance.provided_by = 'inuits'
      expect_commands([
                        /^pcs resource unclone example_vip$/,
                        /^pcs resource delete --force example_vip$/,
                        /^pcs resource create --force example_vip/,
                        /^pcs resource op remove example_vip monitor interval=60s$/
                      ])
      vip_instance.flush
    end
  end
end
