require 'spec_helper'

describe Puppet::Type.type(:cs_order).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
    described_class.expects(:block_until_ready).returns(nil)
  end

  let :test_cib do
    <<-EOS
      <cib>
      <configuration>
        <constraints>
          <rsc_order first="nul-messagebus" first-action="start" id="nul-messagebus_before_nul-interface-2" kind="Mandatory" symmetrical="true" then="nul-interface-2" then-action="start"/>
          <rsc_order first="nul2-messagebus" first-action="promote" id="nul2-messagebus_before_nul-interface-2b" kind="Optional" symmetrical="false" then="nul-interface-2b" then-action="start"/>
        </constraints>
      </configuration>
      </cib>
    EOS
  end

  let :instances do
    Puppet::Util::Execution.expects(:execute).with(%w[crm configure show xml], failonfail: true, combine: true).at_least_once.returns(
      Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
    )
    described_class.instances
  end

  context 'when getting instances' do
    it 'has an instance for each <rsc_order>' do
      expect(instances.count).to eq(2)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "is named by the <primitive>'s id attribute" do
        expect(instance.name).to eq('nul-messagebus_before_nul-interface-2')
      end
    end

    describe 'first instance' do
      let :instance do
        instances.first
      end

      it 'has first equal to nul-messagebus:start' do
        expect(instance.first).to eq('nul-messagebus:start')
      end

      it 'has second equal to nul-interface-2:start' do
        expect(instance.second).to eq('nul-interface-2:start')
      end

      it 'has kind equal to Mandatory' do
        expect(instance.kind).to eq('Mandatory')
      end

      it 'has symmetrical set to true' do
        expect(instance.symmetrical).to eq(true)
      end
    end

    describe 'second instance' do
      let :instance do
        instances[1]
      end

      it 'has first equal to nul2-messagebus:promote' do
        expect(instance.first).to eq('nul2-messagebus:promote')
      end

      it 'has second equal to nul-interface-2b:start' do
        expect(instance.second).to eq('nul-interface-2b:start')
      end

      it 'has kind equal to Optional' do
        expect(instance.kind).to eq('Optional')
      end

      it 'has symmetrical set to false' do
        expect(instance.symmetrical).to eq(false)
      end
    end
  end
end
