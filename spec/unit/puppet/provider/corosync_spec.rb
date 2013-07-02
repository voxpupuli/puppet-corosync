require 'spec_helper'
require 'puppet/provider/corosync'

describe Puppet::Provider::Corosync do
  let :provider do
    described_class.new
  end

  it 'declares a crm_attribute command' do
    expect{
      described_class.command :crm_attribute
    }.to_not raise_error(Puppet::DevError)
  end

  describe '#ready' do
    before do
      # this would probably return nil on the test platform, unless
      # crm_attribute happens to be installed.
      described_class.stubs(:command).with(:crm_attribute).returns 'crm_attribute'
    end

    it 'returns true when crm_attribute exits successfully' do
      Puppet::Util::SUIDManager.expects(:run_and_capture).with(['crm_attribute', '--type', 'crm_config', '--query', '--name', 'dc-version']).returns(['', 0])

      expect(described_class.ready?).to be_true
    end

    it 'returns false when crm_attribute exits unsuccessfully' do
      Puppet::Util::SUIDManager.expects(:run_and_capture).with(['crm_attribute', '--type', 'crm_config', '--query', '--name', 'dc-version']).returns(['', 1])

      expect(described_class.ready?).to be_false
    end
  end
end
