# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:cs_property) do
  subject do
    Puppet::Type.type(:cs_property)
  end

  describe 'with a simple usecase' do
    it 'is able to create an instance' do
      #      Puppet::Type::Cs_clone.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(name: 'maintenance', value: 'false')).not_to be_nil
    end

    [:replace].each do |param|
      it "has a #{param} parameter" do
        expect(subject).to be_validparameter(param)
      end

      it "has documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    [:value].each do |property|
      it "has a #{property} property" do
        expect(subject).to be_validproperty(property)
      end

      it "has documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end
end
