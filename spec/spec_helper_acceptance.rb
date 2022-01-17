# frozen_string_literal: true
require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  case fact_on(host, 'os.family')
  when 'RedHat'
    default_provider = 'pcs'
    pcs_version = if fact_on(host, 'os.release.major').to_i > 7
                    '0.10.0'
                  else
                    '0.9.0'
                  end
  when 'Debian'
    case fact_on(host, 'os.name')
    when 'Debian'
      default_provider = 'pcs'
      pcs_version = '0.10.0'
    when 'Ubuntu'
      if fact_on(host, 'os.release.major').to_i > 18
        default_provider = 'pcs'
        pcs_version = '0.10.0'
      elsif fact_on(host, 'os.release.major').to_i > 16
        default_provider = 'pcs'
        pcs_version = '0.9.0'
      else
        default_provider = 'crm'
        pcs_version = ''
      end
    end
  when 'Suse'
    default_provider = 'crm'
    pcs_version = ''
  else
    default_provider = 'crm'
    pcs_version = ''
  end
  on host, "echo default_provider=#{default_provider} > /opt/puppetlabs/facter/facts.d/pacemaker-provider.txt"
  on host, "echo pcs_version=#{pcs_version} >> /opt/puppetlabs/facter/facts.d/pacemaker-provider.txt"
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
