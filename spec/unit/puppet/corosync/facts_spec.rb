require 'spec_helper'
require 'puppet/corosync/facts'

describe Puppet::Corosync::Facts::HostData do
  describe '.initialize' do
    let(:pcs_bin) { '/sbin/pcs' }
    let(:version_string) { '0.10.15' }

    context 'pcs is installed' do
      before do
        Puppet::Util::Execution.expects(:execute).with(
          [pcs_bin, '--version'],
          failonfail: true,
          combine: true
        ).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(version_string, 0)
        )
        File.expects(:exist?).with(pcs_bin).at_least_once.returns(true)
      end

      it "sets 'pcs_version_full'" do
        described_class.initialize
        expect(described_class.pcs_version_full).to eq('0.10.15')
      end

      it "sets 'pcs_version_release'" do
        described_class.initialize
        expect(described_class.pcs_version_release).to eq('0')
      end

      it "sets 'pcs_version_major'" do
        described_class.initialize
        expect(described_class.pcs_version_major).to eq('10')
      end

      it "sets 'pcs_version_minor'" do
        described_class.initialize
        expect(described_class.pcs_version_minor).to eq('15')
      end
    end

    context 'pcs is not yet installed' do
      before do
        File.expects(:exist?).with(pcs_bin).at_least_once.returns(false)
      end

      it 'handles the unknown string' do
        described_class.initialize
        expect(described_class.pcs_version_full).to eq('')
        expect(described_class.pcs_version_release).to eq(nil)
        expect(described_class.pcs_version_major).to eq(nil)
        expect(described_class.pcs_version_minor).to eq(nil)
      end
    end
  end

  describe '.check_pcs_version' do
    {
      '0.10.15' => {
        full: '0.10.15',
        release: '0',
        major: '10',
        minor: '15'
      },
      '1.11.0' => {
        full: '1.11.0',
        release: '1',
        major: '11',
        minor: '0'
      },
      '0.9.165' => {
        full: '0.9.165',
        release: '0',
        major: '9',
        minor: '165'
      },
    }.each do |version_string, results|
      it "correctly parses '#{version_string}'" do
        expect(described_class.check_pcs_version(version_string)).to eq(results)
      end
    end
  end
end
