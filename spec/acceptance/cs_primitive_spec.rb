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
      cs_primitive { 'pgsql':
        primitive_class => 'ocf',
        primitive_type => 'pgsql',
        promotable => true,
        provided_by => 'heartbeat',
        parameters => { 'pgctl' => '/bin/pg_ctl', 'psql' => '/bin/psql', 'pgdata' => '/var/lib/pgsql/data/', 'rep_mode' => 'sync', 'restore_command' => 'cp /var/lib/pgsql/pg_archive/%f %p', 'primary_conninfo_opt' => 'keepalives_idle=60 keepalives_interval=5 keepalives_count=5', 'restart_on_promote' => 'true' },
        operations => [
          { 'start' => { 'interval' => '0s', 'timeout' => '60s', 'on-fail' => 'restart' } },
          { 'monitor' => { 'interval' => '4s', 'timeout' => '60s', 'on-fail' => 'restart' } },
          { 'monitor' => { 'interval' => '3s', 'timeout' => '60s', 'on-fail' => 'restart', 'role' => 'Master' } },
          { 'promote' => { 'interval' => '0s', 'timeout' => '60s', 'on-fail' => 'restart' } },
          { 'demote' => { 'interval' => '1s', 'timeout' => '60s', 'on-fail' => 'stop' } },
          { 'stop' => { 'interval' => '0s', 'timeout' => '60s', 'on-fail' => 'block' } },
          { 'notify' => { 'interval' => '0s', 'timeout' => '60s' } },
        ],
        ms_metadata => { 'master-max' => '1', 'master-node-max' => '1', 'clone-max' => '2', 'clone-node-max' => '1', 'notify' => 'true' },
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes => true)
  end

  describe service('corosync') do
    it { is_expected.to be_running }
  end

  it 'should create the resources' do
    command = if fact('osfamily') == 'RedHat'
                'pcs resource show'
              else
                'crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(/pgsql.*pgsql/)
    end
  end
end
