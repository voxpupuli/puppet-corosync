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

  case $facts['os']['family'] {
    'RedHat': {
      $package_crmsh  = false
      $package_pcs    = true
      $package_fence_agents = true
      $package_install_options = undef
      $major_version_corosync_detect_by_distr = '2'
    }

    'Debian': {
      $package_crmsh  = true
      $package_pcs    = false
      $package_fence_agents = false

      case $facts['os']['name'] {
        'Debian': {
          if versioncmp($facts['os']['release']['full'], '9') == 0 {
            $package_install_options = undef
            $major_version_corosync_detect_by_distr = '2'
          }

          if versioncmp($facts['os']['release']['full'], '10') >= 0 {
            $package_install_options = undef
            $major_version_corosync_detect_by_distr = '3'
          }

          if versioncmp($facts['os']['release']['full'], '8') == 0 {
            $package_install_options = ['-t', 'jessie-backports']
            $major_version_corosync_detect_by_distr = '1'
          } else {
            $package_install_options = undef
            $major_version_corosync_detect_by_distr = '2'
          }
        }
        'Ubuntu': {
          $package_install_options = undef
          if versioncmp($facts['os']['release']['full'], '19.10') >= 0 {
            $major_version_corosync_detect_by_distr = '3'
          } else {
            $major_version_corosync_detect_by_distr = '2'
          }
        }
        default : {
          $package_install_options = undef
          $major_version_corosync_detect_by_distr = '2'
        }
      }
    }

    default: {
      fail("Unsupported operating system: ${facts['os']['name']}")
    }
  }

  case $version_corosync {
    /^1.*/: {
      $major_version_corosync = '1'
    }
    /^2.*/: {
      $major_version_corosync = '2'
    }
    /^3.*/: {
      $major_version_corosync = '3'
    }
    default: {
      $major_version_corosync = $major_version_corosync_detect_by_distr
    }
  }
}
