class corosync::params {
  $enable_secauth                      = true
  $authkey_source                      = 'file'
  $authkey                             = '/etc/puppet/ssl/certs/ca.pem'
  $threads                             = $::processorcount
  $port                                = '5405'
  $bind_address                        = $::ipaddress
  $multicast_address                   = 'UNSET'
  $unicast_addresses                   = 'UNSET'
  $force_online                        = false
  $check_standby                       = false
  $debug                               = false
  $log_stderr                          = true
  $syslog_priority                     = 'info'
  $log_function_name                   = false
  $rrp_mode                            = 'none'
  $ttl                                 = false
  $token                               = 3000
  $token_retransmits_before_lost_const = 10
  $votequorum_expected_votes           = false
  $cluster_name                        = undef
  $join                                = 50
  $consensus                           = false
  $max_messages                        = 17

  case $::osfamily {
    'RedHat': {
      $set_votequorum = true
      $compatibility = 'whitetank'
      if versioncmp($::operatingsystemrelease, '7') >= 0 {
        $manage_pacemaker_service = false
      } else {
        $manage_pacemaker_service = true
      }
    }

    'Debian': {
      case $::operatingsystem {
        'Ubuntu': {
          if versioncmp($::operatingsystemrelease, '14.04') >= 0 {
            $compatibility = false
            $set_votequorum = true
            $manage_pacemaker_service = true

            file {'/etc/default/cman':
              ensure  => present,
              content => template('corosync/cman.erb'),
            }

          } else {
            $compatibility = 'whitetank'
            $set_votequorum = false
            $manage_pacemaker_service = false
          }
        }
        default : {
          $compatibility = 'whitetank'
          $set_votequorum = false
          $manage_pacemaker_service = false
        }
      }
    }

    default: {
      fail("Unsupported operating system: ${::operatingsystem}")
    }
  }

}
