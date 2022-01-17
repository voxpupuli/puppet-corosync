# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'corosync' do
  let(:pcs_shadow_cib) { "#{default.puppet['vardir']}/shadow.puppet" }

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
      cs_shadow {
        'puppet':
          autocommit => false,
      }
      cs_property { 'stonith-enabled' :
        value   => 'false',
        cib     => 'puppet',
      } ->
      cs_primitive { 'apache2_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.100', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
        cib             => 'puppet',
        notify          => Cs_commit['puppet']
      } ->
      cs_primitive { 'apache2_service':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.101', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
        cib             => 'puppet',
        notify          => Cs_commit['puppet']
      } ->
      cs_colocation { 'apache2_vip_with_service':
        primitives => [ 'apache2_vip', 'apache2_service' ],
        cib        => 'puppet',
        notify     => Cs_commit['puppet']
      }
      cs_commit {
        'puppet':
      }
    EOS

    apply_manifest(pp, catch_failures: true, debug: false, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  describe service('corosync') do
    it { is_expected.to be_running }
  end

  it 'creates the service resource in the cib' do
    command = if fact('default_provider') == 'pcs'
                if Gem::Version.new(fact('pcs_version')) < Gem::Version.new('0.10.0')
                  'pcs resource show'
                else
                  'pcs resource status'
                end
              else
                'crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{apache2_service.*IPaddr2})
    end
  end

  it 'creates the vip resource in the cib' do
    command = if fact('default_provider') == 'pcs'
                if Gem::Version.new(fact('pcs_version')) < Gem::Version.new('0.10.0')
                  'pcs resource show'
                else
                  'pcs resource status'
                end
              else
                'crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{apache2_vip.*IPaddr2})
    end
  end

  it 'creates the colocation in the cib and apache2_vip is the "with" resource' do
    shell('cibadmin --query') do |r|
      expect(r.stdout).to match(%r{colocation.*\swith-rsc="apache2_vip"})
    end
  end

  it 'creates the colocation in the cib and apache2_service is the main resource' do
    shell('cibadmin --query') do |r|
      expect(r.stdout).to match(%r{colocation.*\srsc="apache2_service"})
    end
  end

  it 'creates the cib and a shadow cib' do
    if fact('default_provider') == 'pcs'
      shell('pcs cluster cib')
      shell("pcs cluster cib -f #{pcs_shadow_cib}")
    else
      shell('cibadmin --query')
      shell('CIB_shadow=puppet cibadmin --query')
    end
  end

  it 'creates the vip resource in the shadow cib' do
    command = if fact('default_provider') == 'pcs'
                if Gem::Version.new(fact('pcs_version')) < Gem::Version.new('0.10.0')
                  "pcs resource show -f #{pcs_shadow_cib}"
                else
                  "pcs resource status -f #{pcs_shadow_cib}"
                end
              else
                'CIB_shadow=puppet crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{apache2_vip.*IPaddr2})
    end
  end

  it 'creates the service resource in the shadow cib' do
    command = if fact('default_provider') == 'pcs'
                if Gem::Version.new(fact('pcs_version')) < Gem::Version.new('0.10.0')
                  "pcs resource show -f #{pcs_shadow_cib}"
                else
                  "pcs resource status -f #{pcs_shadow_cib}"
                end
              else
                'CIB_shadow=puppet crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{apache2_service.*IPaddr2})
    end
  end

  it 'creates the colocation in the shadow cib and apache2_vip is the "with" resource' do
    command = if fact('default_provider') == 'pcs'
                "pcs cluster cib -f #{pcs_shadow_cib} | grep apache2_vip_with_service"
              else
                'CIB_shadow=puppet cibadmin --query | grep apache2_vip_with_service'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{colocation.*\swith-rsc="apache2_vip"})
    end
  end

  it 'creates the colocation in the shadow cib and apache2_service is the main resource' do
    command = if fact('default_provider') == 'pcs'
                "pcs cluster cib -f #{pcs_shadow_cib} | grep apache2_vip_with_service"
              else
                'CIB_shadow=puppet cibadmin --query | grep apache2_vip_with_service'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{colocation.*\srsc="apache2_service"})
    end
  end
end
