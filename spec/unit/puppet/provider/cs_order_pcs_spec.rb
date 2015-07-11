require 'spec_helper'

describe Puppet::Type.type(:cs_order).provider(:pcs) do
  before do
    described_class.stubs(:command).with(:pcs).returns 'pcs'
  end

  context 'when getting instances' do
    let :instances do

      test_cib = <<-EOS
        <cib>
        <configuration>
          <constraints>
            <rsc_order first="first_primitive" first-action="start" id="first_primitive_before_second_primitive" then="second_primitive" then-action="start"/>
          </constraints>
        </configuration>
        </cib>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(['pcs', 'cluster', 'cib']).at_least_once.returns([test_cib, 0])
      else
        Puppet::Util::Execution.expects(:execute).with(['pcs', 'cluster', 'cib'], {:failonfail => true}).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
        )
      end
      instances = described_class.instances
    end

    it 'should have an instance for each <cs_order>' do
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
        expect(instance.name).to eq("first_primitive_before_second_primitive")
      end

      it "should have attributes" do
        expect(instance.first).to eq("first_primitive")
        expect(instance.second).to eq("second_primitive")
        expect(instance.symmetrical).to eq(nil)
#        expect(instance.first-action).to eq("start")
#        expect(instance.then-action).to eq("start")
      end
    end
  end

  context 'when flushing' do
    def expect_update(pattern)
      if Puppet::PUPPETVERSION.to_f < 3.4
        Puppet::Util::SUIDManager.expects(:run_and_capture).with { |*args|
          cmdline=args[0].join(" ")
          expect(cmdline).to match(pattern)
          true
        }.at_least_once.returns(['', 0])
      else
        Puppet::Util::Execution.expects(:execute).with{ |*args|
          cmdline=args[0].join(" ")
          expect(cmdline).to match(pattern)
          true
        }.at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new('', 0)
        )
      end
    end

    let :resource do
      Puppet::Type.type(:cs_order).new(
        :name       => 'first_primitive_before_second_primitive',
        :first      => 'first_primitive',
        :second     => 'second_primitive',
        :provider   => :pcs,
        :ensure     => :present,
        :symmetrical => true)
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    it 'creates order' do
        expect_update(/pcs constraint order first_primitive then second_primitive/)
        instance.flush
    end

    it 'updates first' do
      instance.first = 'update_first_primitive'
      expect_update(/pcs constraint order update_first_primitive then second_primitive/)
      instance.flush
    end

    it 'updates second' do
      instance.second = 'update_second_primitive'
      expect_update(/pcs constraint order first_primitive then update_second_primitive/)
      instance.flush
    end

    it 'updates first and second' do
      instance.first  = 'update_first_primitive'
      instance.second = 'update_second_primitive'
      expect_update(/pcs constraint order update_first_primitive then update_second_primitive/)
      instance.flush
    end

    it 'is not symmetrical' do
      instance.symmetrical = false
      expect_update(/pcs constraint order first_primitive then second_primitive symmetrical=false id=first_primitive_before_second_primitive/)
      instance.flush
    end

  end

end
