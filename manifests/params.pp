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
  $rrp_mode                            = 'none'
  $ttl                                 = false
  $token                               = 3000
  $token_retransmits_before_lost_const = 10
  $votequorum_expected_votes           = false

  case $::osfamily {
    'RedHat': {
      $set_votequorum = true
      $compatibility = 'whitetank'
    }

    'Debian': {
      case $::operatingsystem {
        'Ubuntu': {
          if $lsbmajdistrelease >= 14 {
            $compatibility = false
            $set_votequorum = true

            file {'/etc/default/cman':
              ensure => present,
              content => template('corosync/cman.erb'),
            }

          } else {
            $compatibility = 'whitetank'
            $set_votequorum = false
          }
        }
        default : {
          $compatibility = 'whitetank'
          $set_votequorum = false
        }
      }
    }

    default: {
      fail('Not supported OS')
    }
  }

}
