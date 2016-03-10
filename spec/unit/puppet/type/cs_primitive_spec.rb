require 'spec_helper'

describe Puppet::Type.type(:cs_primitive) do
  subject do
    Puppet::Type.type(:cs_primitive)
  end

  it "should have a 'name' parameter" do
    expect(subject.new(:name => 'mock_primitive')[:name]).to eq('mock_primitive')
  end

  describe 'basic structure' do
    it 'should be able to create an instance' do
      provider_class = Puppet::Type::Cs_primitive.provider(Puppet::Type::Cs_primitive.providers[0])
      Puppet::Type::Cs_primitive.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(:name => 'mock_primitive')).to_not be_nil
    end

    [:name, :primitive_class, :primitive_type, :provided_by, :cib].each do |param|
      it "should have a #{param} parameter" do
        expect(subject.validparameter?(param)).to be_truthy
      end

      it "should have documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    [:parameters, :operations, :metadata, :ms_metadata, :promotable].each do |property|
      it "should have a #{property} property" do
        expect(subject.validproperty?(property)).to be_truthy
      end

      it "should have documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe 'when validating attributes' do
    [:parameters, :operations, :metadata, :ms_metadata].each do |attribute|
      it "should validate that the #{attribute} attribute defaults to a hash" do
        expect(subject.new(:name => 'mock_primitive')[:parameters]).to eq({})
      end

      it "should validate that the #{attribute} attribute must be a hash" do
        expect { subject.new(
          :name       => 'mock_primitive',
          :parameters => 'fail'
        )
        }.to raise_error Puppet::Error, /hash/
      end
    end

    it 'should validate that the promotable attribute can be true/false' do
      [true, false].each do |value|
        expect(subject.new(
          :name       => 'mock_primitive',
          :promotable => value
        )[:promotable]).to eq(value.to_s.to_sym)
      end
    end

    it 'should validate that the promotable attribute cannot be other values' do
      ['fail', 42].each do |value|
        expect { subject.new(
          :name       => 'mock_primitive',
          :promotable => value
        )
        }.to raise_error Puppet::Error, /(true|false)/
      end
    end
  end

  describe 'when munging the operations attributes' do
    it 'should not change arrays' do
      Puppet.expects(:deprecation_warning).never
      expect(subject.new(
        :name => 'mock_primitive',
        :operations => [{ 'start' => { 'interval' => '10' } }, { 'stop' => { 'interval' => '10' } }]
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10' } }
                                   ])
    end
    it 'should convert hashes into array' do
      Puppet.expects(:deprecation_warning).never
      expect(subject.new(
        :name => 'mock_primitive',
        :operations => { 'start' => { 'interval' => '10' }, 'stop' => { 'interval' => '10' } }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10' } }
                                   ])
    end
    it 'should convert hashes into array with correct roles' do
      Puppet.expects(:deprecation_warning).once
      expect(subject.new(
        :name => 'mock_primitive',
        :operations => { 'start' => { 'interval' => '10' }, 'stop:Master' => { 'interval' => '10' } }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10', 'role' => 'Master' } }
                                   ])
    end
    it 'should convert sub-arrays into array' do
      Puppet.expects(:deprecation_warning).once
      expect(subject.new(
        :name => 'mock_primitive',
        :operations => { 'start' => [{ 'interval' => '10' }, { 'interval' => '10', 'role' => 'foo' }], 'stop' => { 'interval' => '10' } }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'start' => { 'interval' => '10', 'role' => 'foo' } },
                                     { 'stop' => { 'interval' => '10' } }
                                   ])
    end
    it 'should convert sub-arrays into array with correct roles' do # That case probably never happens in practice
      Puppet.expects(:deprecation_warning).twice
      expect(subject.new(
        :name => 'mock_primitive',
        :operations => { 'start' => { 'interval' => '10' }, 'stop:Master' => [{ 'interval' => '10' }, { 'interval' => '20' }] }
      ).should(:operations)).to eq([
                                     { 'start' => { 'interval' => '10' } },
                                     { 'stop' => { 'interval' => '10', 'role' => 'Master' } },
                                     { 'stop' => { 'interval' => '20', 'role' => 'Master' } }
                                   ])
    end
  end

  describe 'when diffing the operations attributes' do
    def ops
      subject.new(:name => 'mock_primitive').parameter(:operations)
    end

    it 'should show 1 new op with 1 parameter' do
      expect(ops.change_to_s([], [{ 'start' => { 'interval' => '10' } }])).to eq(
        '1 added: start (interval=10)'
      )
    end

    it 'should show 1 new op with 1 parameter and 1 kept' do
      common = [{ 'monitor' => { 'interval' => '10' } }]
      expect(ops.change_to_s(common, common + [{ 'start' => { 'interval' => '10' } }])).to eq(
        '1 added: start (interval=10) / 1 kept'
      )
    end

    it 'should show 1 new op with 2 parameters' do
      expect(ops.change_to_s([], [{ 'start' => { 'interval' => '10', 'foo' => 'bar' } }])).to eq(
        '1 added: start (interval=10 foo=bar)'
      )
    end

    it 'should show 2 new ops with 1 parameter' do
      expect(ops.change_to_s([], [{ 'start' => { 'interval' => '10' } }, { 'stop' => { 'interval' => '10' } }])).to eq(
        '2 added: start (interval=10) stop (interval=10)'
      )
    end

    it 'should show 1 deleted op with 1 parameter' do
      expect(ops.change_to_s([{ 'start' => { 'interval' => '10' } }], [])).to eq(
        '1 removed: start (interval=10)'
      )
    end

    it 'should show 1 removed op with 2 parameters' do
      expect(ops.change_to_s([{ 'start' => { 'interval' => '10', 'foo' => 'bar' } }], [])).to eq(
        '1 removed: start (interval=10 foo=bar)'
      )
    end

    it 'should show 2 removed ops with 1 parameter' do
      expect(ops.change_to_s([{ 'start' => { 'interval' => '10' } }, { 'stop' => { 'interval' => '10' } }], [])).to eq(
        '2 removed: start (interval=10) stop (interval=10)'
      )
    end
  end
end
