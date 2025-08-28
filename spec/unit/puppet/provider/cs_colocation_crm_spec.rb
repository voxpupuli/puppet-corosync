# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:cs_colocation).provider(:crm) do
  before do
    allow(described_class).to receive(:command).with(:crm).and_return('crm')
  end

  let :test_cib do
    <<-EOS
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
    allow(Puppet::Util::Execution).to receive(:execute).and_return(
      Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
    )
    described_class.instances
  end

  context 'when getting instances' do
    before do
      allow(described_class).to receive(:block_until_ready).and_return(nil)
    end

    it 'has an instance for each <colocation>' do
      expect(instances.count).to eq(1)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a(described_class)
      end

      it "is named by the <primitive>'s id attribute" do
        expect(instance.name).to eq('first_with_second')
      end

      it 'has primitives set to second and first' do
        expect(instance.primitives).to eq(%w[second first])
      end

      it 'has score set to INFINITY' do
        expect(instance.score).to eq('INFINITY')
      end
    end
  end

  context 'when flushing' do
    after do
      instance.flush
    end

    def expect_update(pattern)
      if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
        allow(Puppet::Util::SUIDManager).to receive(:run_and_capture) do |*args|
          expect(File.read(args[3])).to match(pattern) if args.slice(0..2) == %w[configure load update]
          true
        end.and_return(['', 0])
      else
        allow(Puppet::Util::Execution).to receive(:execute) do |*args|
          expect(File.read(args[3])).to match(pattern) if args.slice(0..2) == %w[configure load update]
          true
        end.and_return(
          Puppet::Util::Execution::ProcessOutput.new('', 0)
        )
      end
    end

    context 'with 2 primitives' do
      let :resource do
        Puppet::Type.type(:cs_colocation).new(
          name: 'first_with_second',
          provider: :crm,
          primitives: %w[first second],
          ensure: :present
        )
      end

      let :instance do
        instance = described_class.new(resource)
        instance.create
        instance
      end

      it 'createses colocation with defaults' do
        expect_update(%r{colocation first_with_second INFINITY: second first})
      end

      it 'updates first primitive' do
        instance.primitives = %w[first_updated second]
        expect_update(%r{colocation first_with_second INFINITY: second first_updated})
      end

      it 'updateses second primitive' do
        instance.primitives = %w[first second_updated]
        expect_update(%r{colocation first_with_second INFINITY: second_updated first})
      end

      it 'updateses both primitives' do
        instance.primitives = %w[first_updated second_updated]
        expect_update(%r{colocation first_with_second INFINITY: second_updated first_updated})
      end

      it 'sets score' do
        instance.score = '-INFINITY'
        expect_update(%r{colocation first_with_second -INFINITY: second first})
      end

      it 'adds a third primitive' do
        instance.primitives = %w[first second third]
        expect_update(%r{colocation first_with_second INFINITY: first second third})
      end
    end

    context 'with 3 or more primitives' do
      let :resource do
        Puppet::Type.type(:cs_colocation).new(
          name: 'first_with_second_with_third',
          provider: :crm,
          primitives: %w[first second third],
          ensure: :present
        )
      end

      let :instance do
        instance = described_class.new(resource)
        instance.create
        instance
      end

      it 'creates colocation with 3 primitives' do
        expect_update(%r{colocation first_with_second_with_third INFINITY: first second third})
      end
    end
  end
end
