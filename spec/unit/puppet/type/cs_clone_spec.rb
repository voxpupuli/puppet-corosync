require 'spec_helper'

describe Puppet::Type.type(:cs_clone) do
  subject do
    Puppet::Type.type(:cs_clone)
  end

  it "should have a 'name' parameter" do
    expect(subject.new(:name => "mock_clone")[:name]).to eq("mock_clone")
  end

  describe "basic structure" do
    it "should be able to create an instance" do
      provider_class = Puppet::Type::Cs_clone.provider(Puppet::Type::Cs_clone.providers[0])
      Puppet::Type::Cs_clone.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(:name => "mock_clone")).to_not be_nil
    end

    [:name, :cib].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    [:primitive, :clone_max, :clone_node_max, :notify_clones, :globally_unique,
     :ordered, :interleave].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end

      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe "when validating attributes" do
    [:notify_clones, :globally_unique, :ordered, :interleave].each do |attribute|
      it "should validate that the #{attribute} attribute can be true/false" do
        [true, false].each do |value|
          expect(subject.new(
            :name     => "mock_clone",
            attribute => value
          )[attribute]).to eq(value.to_s.to_sym)
        end
      end

      it "should validate that the #{attribute} attribute cannot be other values" do
        ["fail", 42].each do |value|
          expect{subject.new(
            :name     => "mock_clone",
            attribute => "fail"
          ) }.to raise_error Puppet::Error, /(true|false)/
        end
      end
    end
  end
end
