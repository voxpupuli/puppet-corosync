require 'spec_helper'

describe Puppet::Type.type(:cs_property) do
  subject do
    Puppet::Type.type(:cs_property)
  end

  describe 'with a simple usecase' do
    it 'should be able to create an instance' do
      #      Puppet::Type::Cs_clone.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(:name => 'maintenance', :value => 'false')).to_not be_nil
    end

    [:replace].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    [:value].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end

      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end
end
