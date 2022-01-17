# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'corosync' do
  cert = '-----BEGIN CERTIFICATE-----
MIIDVzCCAj+gAwIBAgIJAJNCo5ZPmKegMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNV
BAYTAlhYMRUwEwYDVQQHDAxEZWZhdWx0IENpdHkxHDAaBgNVBAoME0RlZmF1bHQg
Q29tcGFueSBMdGQwHhcNMTUwMjI2MjI1MjU5WhcNMTUwMzI4MjI1MjU5WjBCMQsw
CQYDVQQGEwJYWDEVMBMGA1UEBwwMRGVmYXVsdCBDaXR5MRwwGgYDVQQKDBNEZWZh
dWx0IENvbXBhbnkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
uCPPbDgErGUVs1pKqv59OatjCEU4P9QcmhDYFR7RBN8m08mIqd+RTuiHUKj6C9Rk
vWQ5bYrGQo/+4E0ziAUuUzzITlpIYLVltca6eBhKUqO3Cd0NMRVc2k4nx5948nwv
9FVOIfOOY6BN2ALglfBfLnhObbzJjs6OSZ7bUCpXVPV01t/61Jj3jQ3+R8b7AaoR
mw7j0uWaFimKt/uag1qqKGw3ilieMhHlG0Da5x9WLi+5VIM0t1rcpR58LLXVvXZB
CrQBucm2xhZsz7R76Ai+NL8zhhyzCZidZ2NtJ3E1wzppcSDAfNrru+rcFSlZ4YG+
lMCqZ1aqKWVXmb8+Vg7IkQIDAQABo1AwTjAdBgNVHQ4EFgQULxI68KhZwEF5Q9al
xZmFDR+Beu4wHwYDVR0jBBgwFoAULxI68KhZwEF5Q9alxZmFDR+Beu4wDAYDVR0T
BAUwAwEB/zANBgkqhkiG9w0BAQUFAAOCAQEAsa0YKPixD6VmDo3pal2qqichHbdT
hUONk2ozzRoaibVocqKx2T6Ho23wb/lDlRUu4K4DMO663uumzI9lNoOewa0MuW1D
J52cejAMVsP3ROOdxBv0HZIVVJ8NLBHNLFOHJEDtvzogLVplzmo59vPAdmQo6eIV
japvs+0tdy9iwHj3z1ZME2Ntm/5TzG537e7Hb2zogatM9aBTUAWlZ1tpoaXuTH52
J76GtqoIOh+CTeY/BMwBotdQdgeR0zvjE9FuLWkhTmRtVFhbVIzJbFlFuYq5d3LH
NWyN0RsTXFaqowV1/HSyvfD7LoF/CrmN5gOAM3Ierv/Ti9uqGVhdGBd/kw=='
  File.open('/tmp/ca.pem', 'w') { |f| f.write(cert) }
  after :all do
    cleanup_cs_resources
  end

  it 'with defaults' do
    pp = <<-EOS
      file { '/tmp/ca.pem':
        ensure  => file,
        content => '#{cert}'
      } ->
      class { 'corosync':
        multicast_address => '224.0.0.1',
        authkey           => '/tmp/ca.pem',
        bind_address      => '127.0.0.1',
        set_votequorum    => true,
        quorum_members    => ['127.0.0.1'],
      }
      cs_property { 'stonith-enabled' :
        value   => 'false',
      } ->
      cs_primitive { 'duncan_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.101', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      } ->
      cs_primitive { 'duncan_vip2':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.102', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      } ->
      cs_group { 'duncan_group':
        primitives => 'duncan_vip2',
      }
    EOS

    apply_manifest(pp, catch_failures: true, debug: false, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  describe service('corosync') do
    it { is_expected.to be_running }
  end

  {
    group: 'duncan_group',
    primitive: 'duncan_vip'
  }.each do |type, property_value|
    context "with #{type} #{property_value}" do
      it 'creates a clone' do
        pp = <<-EOS
         cs_clone { 'duncan_vip_clone_#{type}':
           ensure  => present,
           #{type} => '#{property_value}',
         }
        EOS
        apply_manifest(pp, catch_failures: true, debug: false, trace: true)
        apply_manifest(pp, catch_changes: true, debug: false, trace: true)
        command = "cibadmin --query | grep duncan_vip_clone_#{type}"
        shell(command) do |r|
          expect(r.stdout).to match(%r{<clone})
        end
      end

      it 'DEBUG' do
        shell('cibadmin --query')
      end

      it 'deletes a clone' do
        pp = <<-EOS
         cs_clone { 'duncan_vip_clone_#{type}':
           ensure => absent,
         }
        EOS
        apply_manifest(pp, catch_failures: true, debug: false, trace: true)
        apply_manifest(pp, catch_changes: true, debug: false, trace: true)
        command = "cibadmin --query | grep duncan_vip_clone_#{type}"
        assert_raises(Beaker::Host::CommandFailure) do
          shell(command)
        end
      end

      # rubocop:disable RSpec/RepeatedExample
      context 'with all the parameters' do
        let(:xpath) { "/cib/configuration/resources/clone[@id=\"duncan_vip_complex_clone_#{type}\"]" }
        let(:fetch_clone_command) { "cibadmin --query --xpath '#{xpath}'" }

        def fetch_value_command(name)
          "cibadmin --query --xpath '#{xpath}/meta_attributes/nvpair[@name=\"#{name}\"]'"
        end

        it 'creates the clone' do
          pp = <<-EOS
         cs_clone { 'duncan_vip_complex_clone_#{type}':
           ensure          => present,
           #{type}         => '#{property_value}',
           clone_max       => 42,
           notify_clones   => false,
           clone_node_max  => 2,
           globally_unique => true,
           ordered         => false,
           interleave      => false,
         }
          EOS
          apply_manifest(pp, catch_failures: true, debug: false, trace: true)
          apply_manifest(pp, catch_changes: true, debug: false, trace: true)

          shell(fetch_clone_command) do |r|
            expect(r.stdout).to match(%r{<clone})
          end
        end

        it 'DEBUG' do
          shell('cibadmin --query')
        end

        it 'sets clone_max' do
          shell(fetch_value_command('clone-max')) do |r|
            expect(r.stdout).to match(%r{value="42"})
          end
        end

        it 'sets clone_node_max' do
          shell(fetch_value_command('clone-node-max')) do |r|
            expect(r.stdout).to match(%r{value="2"})
          end
        end

        it 'sets notify_clones' do
          shell(fetch_value_command('notify')) do |r|
            expect(r.stdout).to match(%r{value="false"})
          end
        end

        it 'sets globally_unique' do
          shell(fetch_value_command('globally-unique')) do |r|
            expect(r.stdout).to match(%r{value="true"})
          end
        end

        it 'sets ordered' do
          shell(fetch_value_command('ordered')) do |r|
            expect(r.stdout).to match(%r{value="false"})
          end
        end

        it 'sets interleave' do
          shell(fetch_value_command('interleave')) do |r|
            expect(r.stdout).to match(%r{value="false"})
          end
        end

        it 'changes the clone' do
          pp = <<-EOS
         cs_clone { 'duncan_vip_complex_clone_#{type}':
           ensure          => present,
           #{type}         => '#{property_value}',
           clone_max       => 43,
           clone_node_max  => 1,
           notify_clones   => true,
           globally_unique => false,
           ordered         => true,
           interleave      => true,
         }
          EOS
          apply_manifest(pp, catch_failures: true, debug: false, trace: true)
          apply_manifest(pp, catch_changes: true, debug: false, trace: true)

          shell(fetch_clone_command) do |r|
            expect(r.stdout).to match(%r{<clone})
          end
        end

        it 'changes clone_max' do
          shell(fetch_value_command('clone-max')) do |r|
            expect(r.stdout).to match(%r{value="43"})
          end
        end

        it 'sets clone_node_max' do
          shell(fetch_value_command('clone-node-max')) do |r|
            expect(r.stdout).to match(%r{value="1"})
          end
        end

        it 'changes notify_clones' do
          shell(fetch_value_command('notify')) do |r|
            expect(r.stdout).to match(%r{value="true"})
          end
        end

        it 'changes globally_unique' do
          shell(fetch_value_command('globally-unique')) do |r|
            expect(r.stdout).to match(%r{value="false"})
          end
        end

        it 'changes ordered' do
          shell(fetch_value_command('ordered')) do |r|
            expect(r.stdout).to match(%r{value="true"})
          end
        end

        it 'changes interleave' do
          shell(fetch_value_command('interleave')) do |r|
            expect(r.stdout).to match(%r{value="true"})
          end
        end

        it 'removes some parameters' do
          pp = <<-EOS
         cs_clone { 'duncan_vip_complex_clone_#{type}':
           ensure => present,
           #{type} => '#{property_value}',
           clone_max => 43,
           interleave => true,
         }
          EOS
          apply_manifest(pp, catch_failures: true, debug: false, trace: true)
          apply_manifest(pp, catch_changes: true, debug: false, trace: true)

          shell(fetch_clone_command) do |r|
            expect(r.stdout).to match(%r{<clone})
          end
        end

        it 'keeps clone_max' do
          shell(fetch_value_command('clone-max')) do |r|
            expect(r.stdout).to match(%r{value="43"})
          end
        end

        it 'deletes clone_node_max' do
          assert_raises(Beaker::Host::CommandFailure) do
            shell(fetch_value_command('clone-node-max'))
          end
        end

        it 'deletes notify_clones' do
          assert_raises(Beaker::Host::CommandFailure) do
            shell(fetch_value_command('notify'))
          end
        end

        it 'deletes globally_unique' do
          assert_raises(Beaker::Host::CommandFailure) do
            shell(fetch_value_command('globally-unique'))
          end
        end

        it 'deletes ordered' do
          assert_raises(Beaker::Host::CommandFailure) do
            shell(fetch_value_command('ordered'))
          end
        end

        it 'keeps interleave' do
          shell(fetch_value_command('interleave')) do |r|
            expect(r.stdout).to match(%r{value="true"})
          end
        end
      end
      # rubocop:enable RSpec/RepeatedExample
    end
  end

  context 'After creating the clones' do
    it 'still sees groups and primitives and does not change them' do
      pp = <<-EOS
      cs_primitive { 'duncan_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.101', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      } ->
      cs_primitive { 'duncan_vip2':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.102', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      } ->
      cs_group { 'duncan_group':
        primitives => 'duncan_vip2',
      }
      EOS

      apply_manifest(pp, catch_changes: true, debug: false, trace: true)
    end
  end
end
