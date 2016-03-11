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
      corosync::service { 'pacemaker':
        version => '1',
      }
      if $::osfamily == 'RedHat' {
        exec { 'stop_pacemaker':
          command     => 'service pacemaker stop',
          path        => ['/bin','/sbin','/usr/sbin/'],
          refreshonly => true,
          notify      => Service['corosync'],
          subscribe   => File['/etc/corosync/corosync.conf'],
        }
      }
      unless $::corosync::params::manage_pacemaker_service {
        service { 'pacemaker':
          ensure    => running,
          subscribe => Service['corosync'],
          require   => Corosync::Service['pacemaker'],
          before    => Cs_property['stonith-enabled'],
        }
      }
      cs_property { 'stonith-enabled' :
        value   => 'false',
      } ->
      cs_primitive { 'first_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.142', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      } ->
      cs_primitive { 'second_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.144', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes => true)
  end

  describe service('corosync') do
    it { is_expected.to be_running }
  end

  it 'should create a simple order constraint' do
    pp = <<-EOS
      cs_order { '1_then_2':
        first  => 'first_vip',
        first  => 'second_vip',
      }
    EOS
    apply_manifest(pp, :debug => true, :catch_failures => true)
    apply_manifest(pp, :debug => true, :catch_changes => true)
    shell('cibadmin --query | grep 1_then_2') do |r|
      expect(r.stdout).to match(/rsc_order/)
      expect(r.stdout).to match(/first="first_vip"/)
      expect(r.stdout).to match(/first-action="start"/)
      expect(r.stdout).to match(/second="second_vip"/)
      expect(r.stdout).to match(/second-action="start"/)
      expect(r.stdout).to match(/kind="Mandatory"/)
    end
  end

  it 'should delete an order constraint' do
    pp = <<-EOS
      cs_order { '1_then_2':
        ensure => absent,
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes => true)
    assert_raises(Beaker::Host::CommandFailure) do
      shell('cibadmin --query | grep 1_then_2')
    end
  end

  it 'should create a more complex order constraint' do
    pp = <<-EOS
      cs_order { '1_then_2_complex':
        first  => 'first_vip:stop',
        first  => 'second_vip:promote',
        kind   => 'Optional',
      }
    EOS
    apply_manifest(pp, :debug => true, :catch_failures => true)
    apply_manifest(pp, :debug => true, :catch_changes => true)
    shell('cibadmin --query | grep 1_then_2') do |r|
      expect(r.stdout).to match(/rsc_order/)
      expect(r.stdout).to match(/first="first_vip"/)
      expect(r.stdout).to match(/first-action="stop"/)
      expect(r.stdout).to match(/second="second_vip"/)
      expect(r.stdout).to match(/second-action="promote"/)
      expect(r.stdout).to match(/kind="Optional"/)
    end
  end
end
