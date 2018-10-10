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
  $enable_corosync_service             = true
  $manage_corosync_service             = true
  $enable_pacemaker_service            = true
  $enable_pcsd_service                 = true
  $disable_watchdog                    = false

  case $::osfamily {
    'RedHat': {
      $package_crmsh  = false
      $package_pcs    = true
      $set_votequorum = true
      if versioncmp($::operatingsystemrelease, '7') >= 0 {
        $manage_pacemaker_service = true
        $test_corosync_config = true
      } else {
        $manage_pacemaker_service = false
        $test_corosync_config = false
      }
      $package_install_options = undef
    }

    'Debian': {
      $package_crmsh  = true
      $package_pcs    = false
      case $::operatingsystem {
        'Ubuntu': {
          if versioncmp($::operatingsystemrelease, '14.04') >= 0 {
            $set_votequorum = true
            $manage_pacemaker_service = true

            if versioncmp($::operatingsystemrelease, '16.04') >= 0 {
              $test_corosync_config = true
            } else {

              #FIXME should be moved in another place
              file {'/etc/default/cman':
                ensure  => present,
                content => template('corosync/cman.erb'),
              }

              $test_corosync_config = false
            }
          } else {
            $set_votequorum = false
            $manage_pacemaker_service = false
            $test_corosync_config = false
          }
          $package_install_options = undef
        }
        'Debian': {
          if versioncmp($::operatingsystemrelease, '8') >= 0 {
            $set_votequorum = true
            $manage_pacemaker_service = true
            $test_corosync_config = true
            if versioncmp($::operatingsystemrelease, '8') == 0 {
              $package_install_options = ['-t', 'jessie-backports']
            } else {
              $package_install_options = undef
            }
          } else {
            $set_votequorum = false
            $manage_pacemaker_service = false
            $package_install_options = undef
            $test_corosync_config = false
          }
        }
        default : {
          $set_votequorum = false
          $manage_pacemaker_service = false
          $package_install_options = undef
          $test_corosync_config = false
        }
      }
    }

    default: {
      fail("Unsupported operating system: ${::operatingsystem}")
    }
  }

}
