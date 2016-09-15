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

    apply_manifest(pp, catch_failures: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  describe service('corosync') do
    it { is_expected.to be_running }
  end

  it 'creates the resources' do
    command = if fact('osfamily') == 'RedHat'
                'pcs resource show'
              else
                'crm_resource --list'
              end
    shell(command) do |r|
      expect(r.stdout).to match(%r{pgsql.*pgsql})
    end
  end

  it 'creates a haproxy_vip resources' do
    pp = <<-EOS
    cs_primitive { 'haproxy_vip':
      primitive_class  => 'ocf',
      primitive_type   => 'IPaddr2',
      provided_by      => 'heartbeat',
      parameters       => {
        'ip'           => '1.2.3.4',
        'cidr_netmask' => '24'
      },
      operations       => {
        'monitor'      => {
        'interval'     => '30s' }
      },
    }
    EOS
    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
    shell('cibadmin --query') do |r|
      expect(r.stdout).to match(%r{haproxy_vip})
    end
  end

  it 'removes the target-role' do
    pp = <<-EOS
        cs_primitive { 'test_stop':
          primitive_class => 'ocf',
          primitive_type  => 'IPaddr2',
          provided_by     => 'heartbeat',
          parameters      => { 'ip' => '172.16.210.142', 'cidr_netmask' => '24' },
          operations      => { 'monitor' => { 'interval' => '10s' } },
        }
    EOS
    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)

    shell('crm_resource -r test_stop -m -p target-role -v Stopped')

    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  it 'respects unmanaged_metadata' do
    pp = <<-EOS
        cs_primitive { 'test_stop2':
          primitive_class => 'ocf',
          primitive_type  => 'IPaddr2',
          provided_by     => 'heartbeat',
          parameters      => { 'ip' => '172.16.210.142', 'cidr_netmask' => '24' },
          operations      => { 'monitor' => { 'interval' => '10s' } },
          unmanaged_metadata => ['target-role'],
        }
    EOS
    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)

    shell('crm_resource -r test_stop2 -m -p target-role -v Stopped')

    apply_manifest(pp, catch_changes: true, debug: false, trace: true)

    pp = <<-EOS
        cs_primitive { 'test_stop2':
          primitive_class => 'ocf',
          primitive_type  => 'IPaddr2',
          provided_by     => 'heartbeat',
          parameters      => { 'ip' => '172.16.210.142', 'cidr_netmask' => '24' },
          operations      => { 'monitor' => { 'interval' => '10s' } },
        }
    EOS

    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  it 'accepts 2 metadata names in unmanaged_metadata' do
    pp = <<-EOS
        cs_primitive { 'test_md':
          primitive_class => 'ocf',
          primitive_type  => 'IPaddr2',
          provided_by     => 'heartbeat',
          parameters      => { 'ip' => '172.16.210.142', 'cidr_netmask' => '24' },
          operations      => { 'monitor' => { 'interval' => '10s' } },
          metadata        => {'is-managed' => 'false', 'target-role' => 'stopped'}
        }
    EOS
    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  it 'does set is-managed in test_md' do
    shell('crm_resource -r test_md -q') do |r|
      expect(r.stdout).to match(%r{is-managed.*false})
    end
  end

  it 'does set target-role in test_md' do
    shell('crm_resource -r test_md -q') do |r|
      expect(r.stdout).to match(%r{target-role.*stopped})
    end
  end

  it 'does accept 2 items in unmanaged_metadata' do
    pp = <<-EOS
        cs_primitive { 'test_md':
          primitive_class    => 'ocf',
          primitive_type     => 'IPaddr2',
          provided_by        => 'heartbeat',
          parameters         => { 'ip' => '172.16.210.142', 'cidr_netmask' => '24' },
          operations         => { 'monitor' => { 'interval' => '10s' } },
          unmanaged_metadata => ['target-role', 'is-managed'],
        }
    EOS

    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  it 'does not delete or change is-managed if it is in unmanaged_metadata' do
    shell('crm_resource -r test_md -q') do |r|
      expect(r.stdout).to match(%r{is-managed.*false})
    end
  end

  it 'does not delete or change target-role if it is in unmanaged_metadata' do
    shell('crm_resource -r test_md -q') do |r|
      expect(r.stdout).to match(%r{target-role.*stopped})
    end
  end

  it 'can manage again is-managed' do
    pp = <<-EOS
        cs_primitive { 'test_md':
          primitive_class    => 'ocf',
          primitive_type     => 'IPaddr2',
          provided_by        => 'heartbeat',
          parameters         => { 'ip' => '172.16.210.142', 'cidr_netmask' => '24' },
          operations         => { 'monitor' => { 'interval' => '10s' } },
          unmanaged_metadata => ['target-role'],
        }
    EOS

    apply_manifest(pp, expect_changes: true, debug: true, trace: true)
    apply_manifest(pp, catch_changes: true, debug: false, trace: true)
  end

  it 'does delete is-managed because it is no longer in unmanaged_metadata' do
    shell('crm_resource -r test_md -q') do |r|
      expect(r.stdout).not_to match(%r{is-managed.*false})
    end
  end

  it 'does not delete target-role because it is still in unmanaged_metadata' do
    shell('crm_resource -r test_md -q') do |r|
      expect(r.stdout).to match(%r{target-role.*stopped})
    end
  end

  after :all do
    cleanup_cs_resources
  end
end
