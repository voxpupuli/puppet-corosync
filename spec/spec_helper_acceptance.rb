require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  # On Debian-based, service state transitions (restart, stop) hang indefinitely and
  # lead to test timeouts if there is a service unit of Type=notify involved.
  # Use Type=simple as a workaround. See issue 455.
  if host[:hypervisor] =~ %r{docker} && fact_on(host, 'os.family') == 'Debian'
    on host, 'mkdir /etc/systemd/system/corosync.service.d'
    on host, 'echo -e "[Service]\nType=simple" > /etc/systemd/system/corosync.service.d/10-type-simple.conf'
  end
  # Issue 455: On Centos-based there are recurring problems with the pacemaker systemd service
  # refusing to stop its crmd subprocess leading to test timeouts. Force a fast SigKill here.
  if host[:hypervisor] =~ %r{docker} && fact_on(host, 'os.family') == 'RedHat' && fact_on(host, 'os.release.major') == '7'
    on host, 'mkdir /etc/systemd/system/pacemaker.service.d'
    on host, 'echo -e "[Service]\nSendSIGKILL=yes\nTimeoutStopSec=60s" > /etc/systemd/system/pacemaker.service.d/10-timeout.conf'
  end
end

def cleanup_cs_resources
  pp = <<-EOS
      resources { 'cs_clone' :
        purge => true,
      }
      resources { 'cs_group' :
        purge => true,
      }
      resources { 'cs_colocation' :
        purge => true,
      }
      resources { 'cs_location' :
        purge => true,
      }
    EOS

  apply_manifest(pp, catch_failures: true, debug: false, trace: true)
  apply_manifest(pp, catch_changes: true, debug: false, trace: true)

  pp = <<-EOS
      resources { 'cs_primitive' :
        purge => true,
      }
    EOS

  apply_manifest(pp, catch_failures: true, debug: false, trace: true)
  apply_manifest(pp, catch_changes: true, debug: false, trace: true)
end

RSpec.shared_context 'with faked facts' do
  let(:facts_d) do
    puppet_version = get_puppet_version
    if fact('osfamily') =~ %r{windows}i
      if fact('kernelmajversion').to_f < 6.0
        'C:/Documents and Settings/All Users/Application Data/PuppetLabs/facter/facts.d'
      else
        'C:/ProgramData/PuppetLabs/facter/facts.d'
      end
    elsif Puppet::Util::Package.versioncmp(puppet_version, '4.0.0') < 0 && fact('is_pe', '--puppet') == 'true'
      '/etc/puppetlabs/facter/facts.d'
    else
      '/etc/facter/facts.d'
    end
  end

  before do
    # No need to create on windows, PE creates by default
    shell("mkdir -p '#{facts_d}'") if fact('osfamily') !~ %r{windows}i
  end

  after do
    shell("rm -f '#{facts_d}/fqdn.txt'", acceptable_exit_codes: [0, 1])
  end

  def fake_fact(name, value)
    shell("echo #{name}=#{value} > '#{facts_d}/#{name}.txt'")
  end
end
