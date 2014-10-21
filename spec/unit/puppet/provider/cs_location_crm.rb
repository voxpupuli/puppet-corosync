require 'spec_helper'

describe Puppet::Type.type(:cs_location).provider(:crm) do
  before do
    described_class.stubs(:command).with(:crm).returns 'crm'
  end

  context 'when getting location' do
    let :instances do

      test_cib =<<-EOS
       <configuration>
       </configuration>
     EOS
    end
  end
end
