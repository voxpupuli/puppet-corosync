# frozen_string_literal: true
require 'spec_helper'
require 'spec_helper_corosync'

describe Puppet::Type.type(:cs_primitive).provider(:pcs) do
  include_context 'pcs'

  context 'when getting instances' do
    let :instances do
      cib = <<-EOS
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

      pcs_load_cib(cib)
      described_class.instances
    end

    it 'has an instance for each <primitive>' do
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
        expect(instance.operations).to eq([
                                            { 'start' => { 'interval' => '0', 'timeout' => '60' } },
                                            { 'stop'  => { 'interval' => '0', 'timeout' => '40' } }
                                          ])
      end

      it 'has a utilization property corresponding to <utilization>' do
        expect(instance.utilization).to eq('ram' => '256')
      end

      it 'has a metadata property corresponding to <meta_attributes>' do
        expect(instance.metadata).to eq('target-role' => 'Started',
                                        'priority' => '7')
      end
    end
  end

  context 'when flushing' do
    let :instances do
      cib = <<~EOS
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
                    <primitive class="stonith" id="vmfence" type="fence_vmware_soap">
                      <instance_attributes id="vmfence-instance_attributes">
                        <nvpair id="vmfence-instance_attributes-ipaddr" name="ipaddr" value="vcenter00.example.org"/>
                        <nvpair id="vmfence-instance_attributes-login" name="login" value="service-fence_vmware_soap@vsphere.local"/>
                        <nvpair id="vmfence-instance_attributes-passwd" name="passwd" value="some-secret"/>
                        <nvpair id="vmfence-instance_attributes-pcmk_host_map" name="pcmk_host_map" value="nfs00.example.org:nfs00;nfs01.example.org:nfs01"/>
                        <nvpair id="vmfence-instance_attributes-ssl" name="ssl" value="1"/>
                        <nvpair id="vmfence-instance_attributes-ssl_insecure" name="ssl_insecure" value="1"/>
                        <nvpair id="vmfence-instance_attributes-pcmk_delay_max" name="pcmk_delay_max" value="15"/>
                      </instance_attributes>
                      <operations>
                        <op id="vmfence-monitor-interval-60s" interval="60s" name="monitor"/>
                      </operations>
                      <meta_attributes id="vmfence-meta_attributes"/>
                    </primitive>
                  </resources>
                </configuration>
      EOS

      pcs_load_cib(cib)
      described_class.instances
    end

    let :prefetch do
      described_class.prefetch
    end

    let :resource do
      Puppet::Type.type(:cs_primitive).new(
        name: 'testResource',
        provider: :pcs,
        primitive_class: 'ocf',
        provided_by: 'heartbeat',
        operations: { 'monitor' => { 'interval' => '60s' } },
        primitive_type: 'IPaddr2'
      )
    end

    let :stonith_resource do
      Puppet::Type.type(:cs_primitive).new(
        name: 'testStonith',
        provider: :pcs,
        primitive_class: 'stonith',
        operations: { 'monitor' => { 'interval' => '60s' } },
        primitive_type: 'fence_lpar'
      )
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    let :stonith_instance do
      stonith_instance = described_class.new(stonith_resource)
      stonith_instance.create
      stonith_instance
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

    let :vmfence_instance do
      instances[3]
    end

    it 'can flush without changes' do
      expect_commands(%r{pcs})
      simple_instance.flush
    end

    it 'sets operations' do
      instance.operations = [{ 'monitor' => { 'interval' => '20s' } }]
      expect_commands([
                        %r{^pcs resource create --force --no-default-ops testResource ocf:heartbeat:IPaddr2 op monitor interval=20s$},
                      ])
      instance.flush
    end

    it 'do not remove default operations if explicitely set' do
      instance.operations = [{ 'monitor' => { 'interval' => '60s' } }]
      expect_commands(%r{^pcs resource create --force --no-default-ops testResource ocf:heartbeat:IPaddr2 op monitor interval=60s$})
      instance.flush
    end

    it 'sets utilization' do
      instance.utilization = { 'waffles' => '5' }
      expect_commands(%r{^pcs resource create --force --no-default-ops testResource ocf:heartbeat:IPaddr2 op .* utilization waffles=5$})
      instance.flush
    end

    it 'sets parameters' do
      instance.parameters = { 'fluffyness' => '12' }
      expect_commands(%r{^pcs resource create --force --no-default-ops testResource ocf:heartbeat:IPaddr2 fluffyness=12 op.*})
      instance.flush
    end

    it 'sets metadata' do
      instance.metadata = { 'target-role' => 'Started' }
      expect_commands(%r{^pcs resource create --force --no-default-ops testResource ocf:heartbeat:IPaddr2 op .* meta target-role=Started$})
      instance.flush
    end

    it 'sets the primitive name and type' do
      expect_commands(%r{^pcs resource create --force --no-default-ops testResource ocf:heartbeat:IPaddr2})
      instance.flush
    end

    it 'update operations without changing operations that are already there' do
      vip_op_instance.operations = [
        { 'monitor' => { 'interval' => '20s' } },
        { 'monitor2' => { 'interval' => '20s' } }
      ]
      expect_commands([
                        %r{^pcs resource op remove example_vip_with_op monitor interval=10s$},
                        %r{^pcs resource op remove example_vip_with_op monitor3 interval=30s$},
                        %r{^pcs resource update example_vip_with_op cidr_netmask=24 ip=172.31.110.68 op monitor interval=20s op monitor2 interval=20s}
                      ])
      vip_op_instance.flush
    end

    it "sets a primitive_class parameter corresponding to the <primitive>'s class attribute" do
      vip_instance.primitive_class = 'systemd'
      expect_commands([
                        %r{^pcs resource unclone example_vip$},
                        %r{^pcs resource delete --force example_vip$},
                        %r{^pcs resource create --force --no-default-ops example_vip systemd:heartbeat:IPaddr2},
                      ])
      vip_instance.flush
    end

    it "sets a provided_by parameter corresponding to the <primitive>'s class attribute" do
      vip_instance.provided_by = 'voxpupuli'
      expect_commands([
                        %r{^pcs resource unclone example_vip$},
                        %r{^pcs resource delete --force example_vip$},
                        %r{^pcs resource create --force --no-default-ops example_vip ocf:voxpupuli:IPaddr2},
                      ])
      vip_instance.flush
    end

    it "sets an primitive_type parameter corresponding to the <primitive>'s type attribute" do
      vip_instance.primitive_type = 'IPaddr3'
      expect_commands([
                        %r{^pcs resource unclone example_vip$},
                        %r{^pcs resource delete --force example_vip$},
                        %r{^pcs resource create --force --no-default-ops example_vip ocf:heartbeat:IPaddr3},
                      ])
      vip_instance.flush
    end

    it 'creates a primitive without provided_by parameter' do
      vip_instance.primitive_class = 'systemd'
      vip_instance.provided_by = nil
      vip_instance.primitive_type = 'httpd'
      expect_commands([
                        %r{^pcs resource unclone example_vip$},
                        %r{^pcs resource delete --force example_vip$},
                        %r{^pcs resource create --force --no-default-ops example_vip systemd:httpd},
                      ])
      vip_instance.flush
    end

    it "sets an provided_by parameter corresponding to the <primitive>'s provider attribute" do
      vip_instance.provided_by = 'inuits'
      expect_commands([
                        %r{^pcs resource unclone example_vip$},
                        %r{^pcs resource delete --force example_vip$},
                        %r{^pcs resource create --force --no-default-ops example_vip},
                      ])
      vip_instance.flush
    end

    it 'sets stonith operations' do
      stonith_instance.operations = [{ 'monitor' => { 'interval' => '20s' } }]
      expect_commands(%r{^pcs stonith create --force testStonith fence_lpar op monitor interval=20s$})
      stonith_instance.flush
    end

    it 'does not remove default stonith operations if explicitely set' do
      stonith_instance.operations = [{ 'monitor' => { 'interval' => '60s' } }]
      expect_commands(%r{^pcs stonith create --force testStonith fence_lpar op monitor interval=60s$})
      stonith_instance.flush
    end

    it 'sets stonith parameters' do
      stonith_instance.parameters = {
        'ipaddr' => 'hmc00.example.org',
        'login' => 'service-fence',
        'managed' => 'power-cec0',
        'pcmk_delay_max' => '10s',
        'pcmk_host_map' => 'app01.example.org:app01'
      }
      expect_commands(%r{^pcs stonith create --force testStonith fence_lpar ipaddr=hmc00[.]example[.]org login=service-fence managed=power-cec0 pcmk_delay_max=10s pcmk_host_map=app01[.]example[.]org:app01 op.*})
      stonith_instance.flush
    end

    it 'sets stonith metadata' do
      stonith_instance.metadata = { 'target-role' => 'Started' }
      expect_commands(%r{^pcs stonith create --force testStonith fence_lpar op .* meta target-role=Started$})
      stonith_instance.flush
    end

    it 'sets the stonith primitive name and type' do
      expect_commands(%r{^pcs stonith create --force testStonith fence_lpar})
      stonith_instance.flush
    end

    it 'ignores the provided_by parameter for stonith resources' do
      vmfence_instance.provided_by = 'voxpupuli'
      expect_commands(%r{^pcs stonith update vmfence ipaddr.*$})
      vmfence_instance.flush
    end

    it 'updates existing stonith parameters' do
      vmfence_instance.parameters = {
        'ipaddr' => 'vcenter01.example.org',
        'login' => 'service-fence_vmware_soap@vsphere.local',
        'passwd' => 'some-secret',
        'ssl' => '1',
        'ssl_insecure' => '1',
        'pcmk_host_map' => 'nfs00.example.org:nfs00;nfs01.example.org:nfs01',
        'pcmk_delay_max' => '10s'
      }
      expect_commands(%r{^pcs stonith update vmfence ipaddr=vcenter01[.]example[.]org login=service-fence_vmware_soap@vsphere[.]local passwd=some-secret ssl=1 ssl_insecure=1 pcmk_host_map=nfs00[.]example[.]org:nfs00;nfs01[.]example[.]org:nfs01 pcmk_delay_max=10s$})
      vmfence_instance.flush
    end

    it "sets the stonith primitive_type parameter corresponding to the <primitive>'s type attribute" do
      vmfence_instance.primitive_type = 'fence_vmware_rest'
      expect_commands([
                        %r{^pcs stonith delete --force vmfence$},
                        %r{^pcs stonith create --force vmfence fence_vmware_rest}
                      ])
      vmfence_instance.flush
    end

    it 'creates a stonith primitive without provided_by parameter' do
      vmfence_instance.provided_by = nil
      vmfence_instance.primitive_type = 'fence_vmware_rest'
      expect_commands([
                        %r{^pcs stonith delete --force vmfence$},
                        %r{^pcs stonith create --force vmfence fence_vmware_rest}
                      ])
      vmfence_instance.flush
    end

    it 'updates stonith metadata attributes via recreation' do
      vmfence_instance.metadata = { 'target-role' => 'Started' }
      expect_commands([
                        %r{^pcs stonith delete --force vmfence$},
                        %r{^pcs stonith create --force vmfence fence_vmware_soap ipaddr=.* op monitor interval=60s meta target-role=Started}
                      ])
      vmfence_instance.flush
    end

    it 'updates stonith operations via recreation' do
      vmfence_instance.operations = [{ 'monitor' => { 'interval' => '20s' } }]
      expect_commands([
                        %r{^pcs stonith delete --force vmfence$},
                        %r{^pcs stonith create --force vmfence fence_vmware_soap ipaddr=.* op monitor interval=20s$}
                      ])
      vmfence_instance.flush
    end
  end
end
