# @summary Configures sane defaults based on the operating system.
class corosync::params {
  $enable_secauth                      = true
  $authkey_source                      = 'file'
  $authkey                             = '/etc/puppet/ssl/certs/ca.pem'
  $port                                = 5405
  $bind_address                        = $::ipaddress
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

  case $::osfamily {
    'RedHat': {
      $package_crmsh  = false
      $package_pcs    = true
      $package_fence_agents = true
      $package_install_options = undef
    }

    'Debian': {
      $package_crmsh  = true
      $package_pcs    = false
      $package_fence_agents = false

      case $::operatingsystem {
        'Debian': {
          if versioncmp($::operatingsystemrelease, '8') == 0 {
            $package_install_options = ['-t', 'jessie-backports']
          } else {
            $package_install_options = undef
          }
        }
        default : {
          $package_install_options = undef
        }
      }
    }

    default: {
      fail("Unsupported operating system: ${::operatingsystem}")
    }
  }

}
