require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker do |host|
  # For Debian 8 "jessie", we need
  # - pacemaker and crmsh delivered in jessie-backports only
  # - openhpid post-install may fail (https://bugs.debian.org/785287)
  if fact_on(host, 'os.family') == 'Debian' && fact_on(host, 'os.release.major') == '8'
    on host, 'echo deb http://ftp.debian.org/debian jessie-backports main >> /etc/apt/sources.list'
    on host, 'apt-get update && apt-get install -y openhpid', acceptable_exit_codes: [0, 1, 100]
  end
  # On Debian-based, service state transitions (restart, stop) hang indefinitely and
  # lead to test timeouts if there is a service unit of Type=notify involved.
  # Use Type=simple as a workaround. See issue 455.
  if host[:hypervisor] =~ %r{docker} && fact_on(host, 'os.family') == 'Debian'
    on host, 'mkdir /etc/systemd/system/corosync.service.d'
    on host, 'echo -e "[Service]\nType=simple" > /etc/systemd/system/corosync.service.d/10-type-simple.conf'
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
