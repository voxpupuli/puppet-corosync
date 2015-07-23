require 'spec_helper'

describe Puppet::Type.type(:cs_colocation).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
  end

  before(:all) do
    described_class.expects(:block_until_ready).returns(nil)
  end


  let :test_cib do
    test_cib = <<-EOS
      <cib>
      <configuration>
        <constraints>
          <rsc_colocation id="first_with_second" rsc="first" score="INFINITY" with-rsc="second"/>
        </constraints>
      </configuration>
      </cib>
      EOS
  end

  let :instances do
    if Puppet::PUPPETVERSION.to_f < 3.4
      Puppet::Util::SUIDManager.expects(:run_and_capture).with(['crm', 'configure', 'show', 'xml']).at_least_once.returns([test_cib, 0])
    else
      Puppet::Util::Execution.expects(:execute).with(['crm', 'configure', 'show', 'xml']).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
      )
    end
    described_class.instances
  end

  context 'when getting instances' do
    it 'should have an instance for each <colocation>' do
      expect(instances.count).to eq(1)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "should be a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "should be named by the <primitive>'s id attribute" do
        expect(instance.name).to eq("first_with_second")
      end

      it "should have attributes" do
        expect(instance.primitives).to eq(['second', 'first'])
        expect(instance.score).to eq('INFINITY')
      end
    end
  end

  context 'when flushing' do

    after :each do
      instance.flush
    end

    def expect_update(pattern)
      instance.expects(:crm).with do |*args|
        if args.slice(0..2) == ['configure', 'load', 'update']
          expect(File.read(args[3])).to match(pattern)
        end
      end
    end

    context 'with 2 primitives' do  
      let :resource do
        Puppet::Type.type(:cs_colocation).new(
          :name       => 'first_with_second',
          :provider   => :crm,
          :primitives => [ 'first', 'second' ],
          :ensure     => :present)
      end
  
      let :instance do
        instance = described_class.new(resource)
        instance.create
        instance
      end
  
      it 'should creates colocation with defaults' do
        expect_update(/colocation first_with_second INFINITY: second first/)
      end
  
      it 'should update first primitive' do
        instance.primitives = [ 'first_updated', 'second' ]
        expect_update(/colocation first_with_second INFINITY: second first_updated/)
      end

       it 'should updates second primitive' do
        instance.primitives = [ 'first', 'second_updated' ]
        expect_update(/colocation first_with_second INFINITY: second_updated first/)
      end
  
      it 'should updates both primitives' do
        instance.primitives = [ 'first_updated', 'second_updated' ]
        expect_update(/colocation first_with_second INFINITY: second_updated first_updated/)
      end
 
      it 'should set score' do
        instance.score = '-INFINITY'
        expect_update(/colocation first_with_second -INFINITY: second first/)
      end
  
      it 'should add a third primitive' do
        instance.primitives = [ 'first', 'second', 'third' ]
        expect_update(/colocation first_with_second INFINITY: first second third/)
      end
    end

    context 'with 3 or more primitives' do 
      let :resource do
        Puppet::Type.type(:cs_colocation).new(
          :name       => 'first_with_second_with_third',
          :provider   => :crm,
          :primitives => [ 'first', 'second', 'third' ],
          :ensure     => :present)
      end
  
      let :instance do
        instance = described_class.new(resource)
        instance.create
        instance
      end
  
      it 'should create colocation with 3 primitives' do
        expect_update(/colocation first_with_second_with_third INFINITY: first second third/)
      end
    end
  end
end
