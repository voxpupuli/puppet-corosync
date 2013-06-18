require 'spec_helper'

describe Puppet::Type.type(:cs_primitive).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
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
      Puppet::Util::SUIDManager.expects(:run_and_capture).with(['crm', 'configure', 'show', 'xml']).at_least_once.returns([test_cib, 0])
      instances = described_class.instances
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

      it "has an primitive_class parameter corresponding to the <primitive>'s class attribute" do
        pending 'knowing the proper way to assert this'
        expect(instance.primitive_class).to eq("ocf")
      end

      it "has an primitive_type parameter corresponding to the <primitive>'s type attribute" do
        pending 'knowing the proper way to assert this'
        expect(instance.primitive_type).to eq("Xen")
      end

      it "has an provided_by parameter corresponding to the <primitive>'s provider attribute" do
        pending 'knowing the proper way to assert this'
        expect(instance.provided_by).to eq("heartbeat")
      end

      it 'has a parameters property corresponding to <instance_attributes>' do
        expect(instance.parameters).to eq({
          "xmfile" => "/etc/xen/example_vm.cfg",
          "name" => "example_vm_name",
        })
      end

      it 'has an operations property corresponding to <operations>' do
        expect(instance.operations).to eq({
          "start" => {"interval" => "0", "timeout" => "60"},
          "stop" => {"interval" => "0", "timeout" => "40"},
        })
      end

      it 'has a metadata property corresponding to <meta_attributes>' do
        expect(instance.metadata).to eq({
          "target-role" => "Started",
          "priority" => "7",
        })
      end

      it 'has an ms_metadata property' do
        pending 'investigation into what should be asserted here'
        expect(instance).to respond_to(:ms_metadata)
      end

      it "has a promotable property that is :false" do
        pending "more investigation into what is appropriate to assert here"
        expect(instance.promotable).to eq(:false)
      end
    end
  end
end
