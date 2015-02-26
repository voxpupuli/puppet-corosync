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
        bind_address      => $ipaddress,
        set_votequorum    => true,
        quorum_members    => ['127.0.0.1'],
      }
      corosync::service { 'pacemaker':
        version => '1',
        before  => Service['pacemaker'],
      }
      service { 'pacemaker':
        ensure => running,
      }
      cs_property { 'stonith-enabled' :
        value   => 'false',
      } ->
      cs_primitive { 'nginx_vip':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.100', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      } ->
      cs_primitive { 'nginx_service':
        primitive_class => 'ocf',
        primitive_type  => 'IPaddr2',
        provided_by     => 'heartbeat',
        parameters      => { 'ip' => '172.16.210.101', 'cidr_netmask' => '24' },
        operations      => { 'monitor' => { 'interval' => '10s' } },
      } ->
      cs_colocation { 'vip_with_service':
        primitives => [ 'nginx_vip', 'nginx_service' ],
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    unless fact('osfamily') == 'RedHat' # Something's wrong with the pcs provider
      apply_manifest(pp, :catch_changes => true)
    end
  end

  describe service('corosync') do
    it { is_expected.to be_running }
  end

  it 'should create the resources' do
    if fact('osfamily') == 'RedHat'
      command = 'pcs resource show'
    else
      command = 'crm_resource --list'
    end
    shell(command) do |r|
      expect(r.stdout).to match(/nginx_service.*IPaddr2/)
      expect(r.stdout).to match(/nginx_vip.*IPaddr2/)
    end
  end

  it 'should create the colocation' do
    if fact('osfamily') == 'RedHat'
      command = 'pcs cluster cib'
    else
      command = 'crm configure show'
    end
    shell("#{command} | grep vip_with_service") do |r|
      expect(r.stdout).to match(/colocation.*nginx_service.*nginx_vip/)
    end
  end

end



