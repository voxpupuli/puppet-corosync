require 'spec_helper'

describe Puppet::Type.type(:cs_clone) do
  subject do
    Puppet::Type.type(:cs_clone)
  end

  it "has a 'name' parameter" do
    expect(subject.new(name: 'mock_clone', primitive: 'mock_primitive')[:name]).to eq('mock_clone')
  end

  describe 'basic structure' do
    it 'is able to create an instance' do
      provider_class = Puppet::Type::Cs_clone.provider(Puppet::Type::Cs_clone.providers[0])
      Puppet::Type::Cs_clone.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(name: 'mock_clone', primitive: 'mock_primitive')).not_to be_nil
    end

    %i[name cib].each do |param|
      it "has a #{param} parameter" do
        expect(subject).to be_validparameter(param)
      end

      it "has documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    %i[primitive clone_max clone_node_max notify_clones globally_unique
       ordered interleave].each do |property|
      it "has a #{property} property" do
        expect(subject).to be_validproperty(property)
      end

      it "has documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe 'when validating attributes' do
    %i[notify_clones globally_unique ordered interleave].each do |attribute|
      it "validates that the #{attribute} attribute can be true/false" do
        [true, false].each do |value|
          expect(subject.new(
            name: 'mock_clone',
            primitive: 'mock_primitive',
            attribute => value
          )[attribute]).to eq(value.to_s.to_sym)
        end
      end

      it "validates that the #{attribute} attribute cannot be other values" do
        ['fail', 42].each do |value|
          expect { subject.new(name: 'mock_clone', attribute => value) }. \
            to raise_error Puppet::Error, %r{(true|false)}
        end
      end
    end
  end

  describe 'establishing autorequires between clones and primitives' do
    let(:apache_primitive) { create_cs_primitive_resource('apache') }
    let(:apache_clone) { create_cs_clone_resource('apache') }
    let(:mysql_primitive) { create_cs_primitive_resource('mysql') }
    let(:mysql_clone) { create_cs_clone_resource('ms_mysql') }

    before do
      create_catalog(apache_primitive, apache_clone, mysql_primitive, mysql_clone)
    end

    context 'between a clone and its primitive' do
      let(:autorequire_relationship) { apache_clone.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(apache_clone.autorequire.count).to eq(1)
      end

      it 'has apache primitive as source of autorequire' do
        expect(autorequire_relationship.source).to eq apache_primitive
      end

      it 'has apache clone as target of autorequire' do
        expect(autorequire_relationship.target).to eq apache_clone
      end
    end

    context 'between a clone and its master/slave primitive' do
      let(:autorequire_relationship) { mysql_clone.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(mysql_clone.autorequire.count).to eq(1)
      end

      it 'has mysql primitive as source of autorequire' do
        expect(autorequire_relationship.source).to eq mysql_primitive
      end

      it 'has mysql clone as target of autorequire' do
        expect(autorequire_relationship.target).to eq mysql_clone
      end
    end
  end

  describe 'establishing autorequires between clones and groups' do
    let(:apache_group) { create_cs_group_resource('apache-gr', 'apache') }
    let(:apache_clone) { create_cs_clone_resource_with_group('apache-gr') }

    before do
      create_catalog(apache_group, apache_clone)
    end

    let(:autorequire_relationship) { apache_clone.autorequire[0] } # rubocop:disable RSpec/ScatteredLet

    it 'has exactly one autorequire' do
      expect(apache_clone.autorequire.count).to eq(1)
    end

    it 'has apache group as source of autorequire' do
      expect(autorequire_relationship.source).to eq apache_group
    end

    it 'has apache clone as target of autorequire' do
      expect(autorequire_relationship.target).to eq apache_clone
    end
  end

  describe 'establishing autorequires between clones and shadow cib' do
    let(:puppetcib_shadow) { create_cs_shadow_resource('puppetcib') }
    let(:nginx_clone_in_puppetcib_cib) { create_cs_clone_resource_with_cib('nginx', 'puppetcib') }
    let(:autorequire_relationship) { nginx_clone_in_puppetcib_cib.autorequire[0] }

    before do
      create_catalog(puppetcib_shadow, nginx_clone_in_puppetcib_cib)
    end

    it 'has exactly one autorequire' do
      expect(nginx_clone_in_puppetcib_cib.autorequire.count).to eq(1)
    end

    it 'has puppetcib shadow cib as source of autorequire' do
      expect(autorequire_relationship.source).to eq puppetcib_shadow
    end

    it 'has nginx clone as target of autorequire' do
      expect(autorequire_relationship.target).to eq nginx_clone_in_puppetcib_cib
    end
  end

  describe 'establishing autorequires between clone and services' do
    let(:pacemaker_service) { create_service_resource('pacemaker') }
    let(:corosync_service) { create_service_resource('corosync') }
    let(:mysql_clone) { create_cs_clone_resource('mysql') }

    before do
      create_catalog(pacemaker_service, corosync_service, mysql_clone)
    end

    context 'between a clone and the services' do
      let(:autorequire_first_relationship) { mysql_clone.autorequire[0] }
      let(:autorequire_second_relationship) { mysql_clone.autorequire[1] }

      it 'has exactly 2 autorequire' do
        expect(mysql_clone.autorequire.count).to eq(2)
      end

      it 'has corosync service as source of first autorequire' do
        expect(autorequire_first_relationship.source).to eq corosync_service
      end

      it 'has mysql clone as target of first autorequire' do
        expect(autorequire_first_relationship.target).to eq mysql_clone
      end

      it 'has pacemaker service as source of second autorequire' do
        expect(autorequire_second_relationship.source).to eq pacemaker_service
      end

      it 'has mysql clone as target of second autorequire' do
        expect(autorequire_second_relationship.target).to eq mysql_clone
      end
    end
  end
end
