require 'spec_helper'

describe Puppet::Type.type(:cs_location) do
  subject do
    Puppet::Type.type(:cs_location)
  end

  it "has a 'name' parameter" do
    expect(subject.new(name: 'mock_location')[:name]).to eq('mock_location')
  end

  describe 'basic structure' do
    it 'is able to create an instance' do
      provider_class = Puppet::Type::Cs_location.provider(Puppet::Type::Cs_location.providers[0])
      Puppet::Type::Cs_location.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(name: 'mock_location')).not_to be_nil
    end

    %i[name cib].each do |param|
      it "has a #{param} parameter" do
        expect(subject).to be_validparameter(param)
      end

      it "has documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    %i[primitive node_name resource_discovery score rules].each do |property|
      it "has a #{property} property" do
        expect(subject).to be_validproperty(property)
      end

      it "has documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe 'establishing autorequires between locations and primitives' do
    let(:apache_primitive) { create_cs_primitive_resource('apache') }
    let(:apache_location) { create_cs_location_resource('apache') }
    let(:mysql_primitive) { create_cs_primitive_resource('mysql') }
    let(:mysql_location) { create_cs_location_resource('ms_mysql') }

    before do
      create_catalog(apache_primitive, apache_location, mysql_primitive, mysql_location)
    end

    context 'between a location and its primitive' do
      let(:autorequire_relationship) { apache_location.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(apache_location.autorequire.count).to eq(1)
      end

      it 'has apache primitive as source of autorequire' do
        expect(autorequire_relationship.source).to eq apache_primitive
      end

      it 'has apache location as target of autorequire' do
        expect(autorequire_relationship.target).to eq apache_location
      end
    end

    context 'between a location and its master/slave primitive' do
      let(:autorequire_relationship) { mysql_location.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(mysql_location.autorequire.count).to eq(1)
      end

      it 'has mysql primitive as source of autorequire' do
        expect(autorequire_relationship.source).to eq mysql_primitive
      end

      it 'has mysql location as target of autorequire' do
        expect(autorequire_relationship.target).to eq mysql_location
      end
    end
  end

  describe 'establishing autorequires between locations and shadow cib' do
    let(:puppetcib_shadow) { create_cs_shadow_resource('puppetcib') }
    let(:nginx_location_in_puppetcib_cib) { create_cs_location_resource_with_cib('nginx', 'puppetcib') }

    before do
      create_catalog(puppetcib_shadow, nginx_location_in_puppetcib_cib)
    end

    context 'between a location and its shadow cib' do
      let(:autorequire_relationship) { nginx_location_in_puppetcib_cib.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(nginx_location_in_puppetcib_cib.autorequire.count).to eq(1)
      end

      it 'has puppetcib shadow cib as source of autorequire' do
        expect(autorequire_relationship.source).to eq puppetcib_shadow
      end

      it 'has nginx location as target of autorequire' do
        expect(autorequire_relationship.target).to eq nginx_location_in_puppetcib_cib
      end
    end
  end

  describe 'establishing autorequires between locations and clones' do
    let(:apache_clone) { create_cs_clone_resource('apache') }
    let(:apache_location) { create_cs_location_resource('apache_clone') }

    before do
      create_catalog(apache_clone, apache_location)
    end

    context 'between a location and its clone' do
      let(:autorequire_relationship) { apache_location.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(apache_location.autorequire.count).to eq(1)
      end

      it 'has apache clone as source of autorequire' do
        expect(autorequire_relationship.source).to eq apache_clone
      end

      it 'has apache location as target of autorequire' do
        expect(autorequire_relationship.target).to eq apache_location
      end
    end
  end

  describe 'establishing autorequires between locations and groups' do
    let(:apache_group) { create_cs_group_resource('apache_group', %w[apache_vip apache_service]) }
    let(:apache_location) { create_cs_location_resource('apache_group') }

    before do
      create_catalog(apache_group, apache_location)
    end

    context 'between a location and its group' do
      let(:autorequire_relationship) { apache_location.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(apache_location.autorequire.count).to eq(1)
      end

      it 'has apache group as source of autorequire' do
        expect(autorequire_relationship.source).to eq apache_group
      end

      it 'has apache location as target of autorequire' do
        expect(autorequire_relationship.target).to eq apache_location
      end
    end
  end

  describe 'establishing autorequires between location and services' do
    let(:pacemaker_service) { create_service_resource('pacemaker') }
    let(:corosync_service) { create_service_resource('corosync') }
    let(:mysql_location) { create_cs_location_resource('mysql') }

    before do
      create_catalog(pacemaker_service, corosync_service, mysql_location)
    end

    context 'between a location and the services' do
      let(:autorequire_first_relationship) { mysql_location.autorequire[0] }
      let(:autorequire_second_relationship) { mysql_location.autorequire[1] }

      it 'has exactly 2 autorequire' do
        expect(mysql_location.autorequire.count).to eq(2)
      end

      it 'has corosync service as source of first autorequire' do
        expect(autorequire_first_relationship.source).to eq corosync_service
      end

      it 'has mysql location as target of first autorequire' do
        expect(autorequire_first_relationship.target).to eq mysql_location
      end

      it 'has pacemaker service as source of second autorequire' do
        expect(autorequire_second_relationship.source).to eq pacemaker_service
      end

      it 'has mysql location as target of second autorequire' do
        expect(autorequire_second_relationship.target).to eq mysql_location
      end
    end
  end
end
