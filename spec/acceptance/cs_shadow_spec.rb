#! /usr/bin/env ruby -S rspec
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
      cs_shadow {
        'puppet':
          autocommit => false,
      }
      cs_primitive { 'apache_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.100', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
        cib             => 'puppet',
      } ->
      cs_primitive { 'apache_service':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.101', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
        cib             => 'puppet',
      } ->
      cs_colocation { 'apache_vip_with_service':
        primitives => [ 'apache_vip', 'apache_service' ],
        cib        => 'puppet',
      }
    EOS

    apply_manifest(pp, catch_failures: true, debug: true, trace: true)
    # This catalog should always generate changes because we did not put a cs_commit resource and
    # we have set autocommit to false.
    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
  end

  describe service('corosync') do
    it { is_expected.to be_running }
  end

  it 'does not create the service resource in the cib' do
    command = if fact('osfamily') == 'RedHat'
                'pcs resource show'
              else
                'crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).not_to match(%r{apache_service.*IPaddr2})
    end
  end

  it 'does not create the vip resource in the cib' do
    command = if fact('osfamily') == 'RedHat'
                'pcs resource show'
              else
                'crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).not_to match(%r{apache_vip.*IPaddr2})
    end
  end

  it 'does not create the colocation identified by with-rsc="apache_vip" in the cib' do
    shell('cibadmin --query') do |r|
      expect(r.stdout).not_to match(%r{colocation.*\swith-rsc="apache_vip"})
    end
  end

  it 'does not create the colocation identified by rsc="apache_service" in the cib' do
    shell('cibadmin --query') do |r|
      expect(r.stdout).not_to match(%r{colocation.*\srsc="apache_service"})
    end
  end

  it 'creates the service resource in the shadow cib' do
    command = if fact('osfamily') == 'RedHat'
                'CIB_shadow=puppet pcs resource show'
              else
                'CIB_shadow=puppet crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{apache_service.*IPaddr2})
    end
  end

  it 'creates the vip resource in the shadow cib' do
    command = if fact('osfamily') == 'RedHat'
                'CIB_shadow=puppet pcs resource show'
              else
                'CIB_shadow=puppet crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{apache_vip.*IPaddr2})
    end
  end

  it 'creates the colocation identified by with-rsc="apache_vip" in the shadow cib' do
    shell('CIB_shadow=puppet cibadmin --query | grep apache_vip_with_service') do |r|
      expect(r.stdout).to match(%r{colocation.*\swith-rsc="apache_vip"})
    end
  end

  it 'creates the colocation identified by rsc="apache_service" in the shadow cib' do
    shell('CIB_shadow=puppet cibadmin --query | grep apache_vip_with_service') do |r|
      expect(r.stdout).to match(%r{colocation.*\srsc="apache_service"})
    end
  end

  after :all do
    cleanup_cs_resources
  end
end
