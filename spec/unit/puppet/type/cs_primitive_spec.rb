# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:cs_primitive) do
  subject do
    Puppet::Type.type(:cs_primitive)
  end

  it "has a 'name' parameter" do
    expect(subject.new(name: 'mock_primitive')[:name]).to eq('mock_primitive')
  end

  describe 'basic structure' do
    it 'is able to create an instance' do
      provider_class = Puppet::Type::Cs_primitive.provider(Puppet::Type::Cs_primitive.providers[0])
      Puppet::Type::Cs_primitive.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(name: 'mock_primitive')).not_to be_nil
    end

    %i[name primitive_class primitive_type provided_by cib].each do |param|
      it "has a #{param} parameter" do
        expect(subject).to be_validparameter(param)
      end

      it "has documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    %i[parameters operations metadata].each do |property|
      it "has a #{property} property" do
        expect(subject).to be_validproperty(property)
      end

      it "has documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe 'when validating attributes' do
    %i[parameters operations metadata].each do |attribute|
      it "validates that the #{attribute} attribute defaults to a hash" do
        expect(subject.new(name: 'mock_primitive')[:parameters]).to eq({})
      end

      it "validates that the #{attribute} attribute must be a hash" do
        expect do
          subject.new(
            name: 'mock_primitive',
            parameters: 'fail'
          )
        end.to raise_error Puppet::Error, %r{hash}
      end
    end
  end

  describe 'when munging the operations attributes' do
    it 'does not change arrays' do
      Puppet.expects(:deprecation_warning).never
      expect(subject.new(
        name: 'mock_primitive',
        operations: [{ 'start' => { 'interval' => '10' } }, { 'stop' => { 'interval' => '10' } }]
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10' } }
                                   ])
    end

    it 'converts hashes into array' do
      Puppet.expects(:deprecation_warning).never
      expect(subject.new(
        name: 'mock_primitive',
        operations: { 'start' => { 'interval' => '10' }, 'stop' => { 'interval' => '10' } }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10' } }
                                   ])
    end

    it 'converts hashes into array with correct roles' do
      Puppet.expects(:deprecation_warning).once
      expect(subject.new(
        name: 'mock_primitive',
        operations: { 'start' => { 'interval' => '10' }, 'stop:Master' => { 'interval' => '10' } }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10', 'role' => 'Master' } }
                                   ])
    end

    it 'converts sub-arrays into array' do
      Puppet.expects(:deprecation_warning).once
      expect(subject.new(
        name: 'mock_primitive',
        operations: { 'start' => [{ 'interval' => '10' }, { 'interval' => '10', 'role' => 'foo' }], 'stop' => { 'interval' => '10' } }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'start' => { 'interval' => '10', 'role' => 'foo' } },
                                     { 'stop' => { 'interval' => '10' } }
                                   ])
    end

    it 'converts sub-arrays into array with correct roles' do # That case probably never happens in practice
      Puppet.expects(:deprecation_warning).twice
      expect(subject.new(
        name: 'mock_primitive',
        operations: { 'start' => { 'interval' => '10' }, 'stop:Master' => [{ 'interval' => '10' }, { 'interval' => '20' }] }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10', 'role' => 'Master' } },
                                     { 'stop' => { 'interval' => '20', 'role' => 'Master' } }
                                   ])
    end
  end

  describe 'when diffing the operations attributes' do
    def ops
      subject.new(name: 'mock_primitive').parameter(:operations)
    end

    it 'shows 1 new op with 1 parameter' do
      expect(ops.change_to_s([], [{ 'start' => { 'interval' => '10' } }])).to eq(
        '1 added: start (interval=10)'
      )
    end

    it 'shows 1 new op with 1 parameter and 1 kept' do
      common = [{ 'monitor' => { 'interval' => '10' } }]
      expect(ops.change_to_s(common, common + [{ 'start' => { 'interval' => '10' } }])).to eq(
        '1 added: start (interval=10) / 1 kept'
      )
    end

    it 'shows 1 new op with 2 parameters' do
      expect(ops.change_to_s([], [{ 'start' => { 'interval' => '10', 'foo' => 'bar' } }])).to eq(
        '1 added: start (interval=10 foo=bar)'
      )
    end

    it 'shows 2 new ops with 1 parameter' do
      expect(ops.change_to_s([], [{ 'start' => { 'interval' => '10' } }, { 'stop' => { 'interval' => '10' } }])).to eq(
        '2 added: start (interval=10) stop (interval=10)'
      )
    end

    it 'shows 1 deleted op with 1 parameter' do
      expect(ops.change_to_s([{ 'start' => { 'interval' => '10' } }], [])).to eq(
        '1 removed: start (interval=10)'
      )
    end

    it 'shows 1 removed op with 2 parameters' do
      expect(ops.change_to_s([{ 'start' => { 'interval' => '10', 'foo' => 'bar' } }], [])).to eq(
        '1 removed: start (interval=10 foo=bar)'
      )
    end

    it 'shows 2 removed ops with 1 parameter' do
      expect(ops.change_to_s([{ 'start' => { 'interval' => '10' } }, { 'stop' => { 'interval' => '10' } }], [])).to eq(
        '2 removed: start (interval=10) stop (interval=10)'
      )
    end
  end
end
