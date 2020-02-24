# @summary Configures sane defaults based on the operating system.
class corosync::params {
  $enable_secauth                      = true
  $authkey_source                      = 'file'
  $authkey                             = '/etc/puppet/ssl/certs/ca.pem'
  $port                                = 5405
  $bind_address                        = $facts['networking']['ip']
  $force_online                        = false
  $check_standby                       = false
  $log_timestamp                       = false
  $log_file                            = true
  $debug                               = false
  $log_stderr                          = true
  $syslog_priority                     = 'info'
  $log_function_name                   = false
  $package_corosync                    = true
  $package_pacemaker                   = true
  $version_corosync                    = 'present'
  $version_crmsh                       = 'present'
  $version_pacemaker                   = 'present'
  $version_pcs                         = 'present'
  $version_fence_agents                = 'present'
  $enable_corosync_service             = true
  $manage_corosync_service             = true
  $enable_pacemaker_service            = true
  $enable_pcsd_service                 = true
  $package_quorum_device               = 'corosync-qdevice'
  $set_votequorum                      = true
  $manage_pacemaker_service            = true
  $test_corosync_config                = true

  $package_install_options = $facts['os']['release']['major'] ? {
    '8'     => ['--enablerepo=ha'],
    default => undef,
  }

  case $facts['os']['family'] {
    'RedHat': {
      $package_crmsh  = false
      $package_pcs    = true
      $package_fence_agents = true
      if versioncmp($facts['os']['release']['major'], '8') >= 0 {
        $test_corosync_config_cmd = '/usr/sbin/corosync -c % -t'
      } else {
        $test_corosync_config_cmd = '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t'
      }
    }

    'Debian': {
      $package_crmsh  = true
      $package_pcs    = false
      $package_fence_agents = false
      $test_corosync_config_cmd = '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t'
    }

    'Suse': {
      case $facts['os']['name'] {
        'SLES': {
          $package_crmsh  = true
          $package_pcs    = false
          $package_fence_agents = false
          $test_corosync_config_cmd = '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t'
        }
        default: {
          fail("Unsupported flavour of ${facts['os']['family']}: ${facts['os']['name']}")
        }
      }
    }

    default: {
      fail("Unsupported operating system: ${facts['os']['name']}")
    }
  }
}
