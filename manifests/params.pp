class corosync::params {
  $enable_secauth                      = true
  $authkey_source                      = 'file'
  $authkey                             = '/etc/puppet/ssl/certs/ca.pem'
  $threads                             = undef
  $port                                = '5405'
  $bind_address                        = $::ipaddress
  $multicast_address                   = 'UNSET'
  $unicast_addresses                   = 'UNSET'
  $force_online                        = false
  $check_standby                       = false
  $log_file                            = true
  $debug                               = false
  $log_stderr                          = true
  $syslog_priority                     = 'info'
  $log_function_name                   = false
  $rrp_mode                            = undef
  $ttl                                 = false
  $vsftype                             = undef
  $token                               = undef
  $token_retransmits_before_loss_const = undef
  $votequorum_expected_votes           = false
  $cluster_name                        = undef
  $join                                = undef
  $consensus                           = undef
  $max_messages                        = undef
  $package_corosync                    = true
  $package_pacemaker                   = true
  $version_corosync                    = 'present'
  $version_crmsh                       = 'present'
  $version_pacemaker                   = 'present'
  $version_pcs                         = 'present'
  $compatibility                       = undef

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
            $package_install_options = ['-t', 'jessie-backports']
            $test_corosync_config = true
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
