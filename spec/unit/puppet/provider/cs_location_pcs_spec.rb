# frozen_string_literal: true
require 'spec_helper'

describe Puppet::Type.type(:cs_location).provider(:pcs) do
  include_context 'pcs'

  let :instances do
    cib = <<-EOS
      <cib>
      <configuration>
        <constraints>
          <rsc_location id="clusterip_on_node_primary" node="primary" rsc="ClusterIP" score="100"/>
          <rsc_location id="foobar_on_onetwo" node="onetwo" rsc="FooBar"/>
          <rsc_location id="dont-run-apache-on-c001n03" rsc="myApacheRsc">
              <rule id="dont-run-apache-rule" score="-INFINITY">
                <expression id="dont-run-apache-expr" attribute="#uname"
                            operation="eq" value="c00n03"/>
              </rule>
          </rsc_location>
        </constraints>
      </configuration>
      </cib>
    EOS

    pcs_load_cib(cib)
    described_class.instances
  end

  context 'when getting instances' do
    it 'has an instance for each <rsc_location>' do
      expect(instances.count).to eq(3)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end
    end

    describe 'first instance' do
      let :instance do
        instances.first
      end

      it 'has name equal to clusterip_on_node_primary' do
        expect(instance.name).to eq('clusterip_on_node_primary')
      end

      it 'has primitive equal to ClusterIP' do
        expect(instance.primitive).to eq('ClusterIP')
      end

      it 'has score equal to 100' do
        expect(instance.score).to eq('100')
      end
    end

    describe 'second instance' do
      let :instance do
        instances[1]
      end

      it 'has name equal to foobar_on_onetwo' do
        expect(instance.name).to eq('foobar_on_onetwo')
      end

      it 'has primitive equal to FooBar' do
        expect(instance.primitive).to eq('FooBar')
      end

      it 'has score equal to INFINITY' do
        expect(instance.score).to eq('INFINITY')
      end
    end

    # Inspired by http://clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/_using_rules_to_determine_resource_location.html
    # Released under CC-BY-SA
    describe 'third instance' do
      let :instance do
        instances[2]
      end

      it 'has name equal to dont-run-apache-on-c001n03' do
        expect(instance.name).to eq('dont-run-apache-on-c001n03')
      end

      it 'has primitive equal to myApacheRsc' do
        expect(instance.primitive).to eq('myApacheRsc')
      end

      it 'has score equal to INFINITY' do
        expect(instance.score).to eq('INFINITY')
      end

      it 'has correct rules' do
        expect(instance.rules).to eq([{
                                       'dont-run-apache-rule' => {
                                         'score' => '-INFINITY',
                                         'expression' => [
                                           { 'operation' => 'eq',
                                             'value' => 'c00n03',
                                             'attribute' => '#uname' }
                                         ]
                                       }
                                     }])
      end
    end

    describe 'changing a resource' do
      let :resource do
        Puppet::Type.type(:cs_location).new(
          name: 'testlocation',
          provider: :pcs,
          primitive: 'apache',
          score: 'INFINITY'
        )
      end

      let :instance do
        instance = described_class.new(resource)
        instance.create
        instance
      end

      it 'can get a rule' do
        instance.rules = [{
          'dont-run-apache-rule' => {
            'score' => '-INFINITY',
            'expression' => [
              { 'operation' => 'eq',
                'value' => 'c00n03',
                'attribute' => '#uname' }
            ]
          }
        }]
        expect_commands([
                          %r{^pcs constraint remove testlocation$},
                          %r{^pcs constraint location apache rule id=dont-run-apache-rule constraint-id=testlocation score=-INFINITY #uname eq c00n03$}
                        ])
        instance.flush
      end

      it 'can get two rules' do
        instance.rules = [{
          'dont-run-apache-rule-2' => {
            'score' => '200',
            'expression' => [
              { 'operation' => 'lt',
                'value' => 'container',
                'attribute' => '#kind' }
            ]
          }
        }, {
          'dont-run-apache-rule' => {
            'score' => '-INFINITY',
            'expression' => [
              { 'operation' => 'eq',
                'value' => 'c00n03',
                'attribute' => '#uname' }
            ]
          }
        }]
        expect_commands([
                          %r{^pcs constraint remove testlocation$},
                          %r{^pcs constraint location apache rule id=dont-run-apache-rule-2 constraint-id=testlocation score=200 #kind lt container$},
                          %r{^pcs constraint rule add testlocation id=dont-run-apache-rule score=-INFINITY #uname eq c00n03$}
                        ])
        instance.flush
      end
    end
  end
end
