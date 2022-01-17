# frozen_string_literal: true
require 'spec_helper'

describe Puppet::Type.type(:cs_group) do
  subject do
    Puppet::Type.type(:cs_group)
  end

  it "has a 'name' parameter" do
    expect(subject.new(name: 'mock_group')[:name]).to eq('mock_group')
  end

  describe 'basic structure' do
    it 'is able to create an instance' do
      provider_class = Puppet::Type::Cs_group.provider(Puppet::Type::Cs_group.providers[0])
      Puppet::Type::Cs_group.expects(:defaultprovider).returns(provider_class)

      expect(subject.new(name: 'mock_group')).not_to be_nil
    end

    %i[name cib].each do |param|
      it "has a #{param} parameter" do
        expect(subject).to be_validparameter(param)
      end

      it "has documentation for its #{param} parameter" do
        expect(subject.paramclass(param).doc).to be_instance_of(String)
      end
    end

    [:primitives].each do |property|
      it "has a #{property} property" do
        expect(subject).to be_validproperty(property)
      end

      it "has documentation for its #{property} property" do
        expect(subject.propertybyname(property).doc).to be_instance_of(String)
      end
    end
  end

  describe 'establishing autorequires between groups and primitives' do
    let(:apache_primitive) { create_cs_primitive_resource('apache') }
    let(:apache_group) { create_cs_group_resource('apachegroup', ['apache']) }
    let(:mysql_primitive) { create_cs_primitive_resource('mysql') }
    let(:mysql_group) { create_cs_group_resource('ms_mysqlgroup', ['mysql']) }

    before do
      create_catalog(apache_primitive, apache_group, mysql_primitive, mysql_group)
    end

    context 'between a group and its primitive' do
      let(:autorequire_relationship) { apache_group.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(apache_group.autorequire.count).to eq(1)
      end

      it 'has apache primitive as source of autorequire' do
        expect(autorequire_relationship.source).to eq apache_primitive
      end

      it 'has apache group as target of autorequire' do
        expect(autorequire_relationship.target).to eq apache_group
      end
    end

    context 'between a group and its master/slave primitive' do
      let(:autorequire_relationship) { mysql_group.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(mysql_group.autorequire.count).to eq(1)
      end

      it 'has mysql primitive as source of autorequire' do
        expect(autorequire_relationship.source).to eq mysql_primitive
      end

      it 'has mysql group as target of autorequire' do
        expect(autorequire_relationship.target).to eq mysql_group
      end
    end
  end

  describe 'establishing autorequires between groups and shadow cib' do
    let(:puppetcib_shadow) { create_cs_shadow_resource('puppetcib') }
    let(:nginx_group_in_puppetcib_cib) { create_cs_group_resource_with_cib('nginxgroup', ['nginx'], 'puppetcib') }

    before do
      create_catalog(puppetcib_shadow, nginx_group_in_puppetcib_cib)
    end

    context 'between a group and its shadow cib' do
      let(:autorequire_relationship) { nginx_group_in_puppetcib_cib.autorequire[0] }

      it 'has exactly one autorequire' do
        expect(nginx_group_in_puppetcib_cib.autorequire.count).to eq(1)
      end

      it 'has puppetcib shadow cib as source of autorequire' do
        expect(autorequire_relationship.source).to eq puppetcib_shadow
      end

      it 'has nginx group as target of autorequire' do
        expect(autorequire_relationship.target).to eq nginx_group_in_puppetcib_cib
      end
    end
  end

  describe 'establishing autorequires between groups and services' do
    let(:pacemaker_service) { create_service_resource('pacemaker') }
    let(:corosync_service) { create_service_resource('corosync') }
    let(:mysql_group) { create_cs_group_resource('mysqlgroup', ['mysql']) }

    before do
      create_catalog(pacemaker_service, corosync_service, mysql_group)
    end

    context 'between a group and the services' do
      let(:autorequire_first_relationship) { mysql_group.autorequire[0] }
      let(:autorequire_second_relationship) { mysql_group.autorequire[1] }

      it 'has exactly 2 autorequire' do
        expect(mysql_group.autorequire.count).to eq(2)
      end

      it 'has corosync service as source of first autorequire' do
        expect(autorequire_first_relationship.source).to eq corosync_service
      end

      it 'has mysql group as target of first autorequire' do
        expect(autorequire_first_relationship.target).to eq mysql_group
      end

      it 'has pacemaker service as source of second autorequire' do
        expect(autorequire_second_relationship.source).to eq pacemaker_service
      end

      it 'has mysql group as target of second autorequire' do
        expect(autorequire_second_relationship.target).to eq mysql_group
      end
    end
  end
end
