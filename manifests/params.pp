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
  $packages                            = ['corosync', 'pacemaker']
  $expected_votes                      = undef
  $quorum_members                      = undef
  $two_node                            = undef
  $token                               = 3000
  $token_retransmits_before_lost_const = 10

  case $::osfamily {
    'RedHat': {
      $set_votequorum = true
    }

    'Debian': {
      if ($::operatingsystem == 'Ubuntu' and
          $::operatingsystemrelease >= '14.04') {
        $set_votequorum = true
      } else {
        $set_votequorum = false
      }
    }

    default: {
      fail('Not supported OS')
    }
  }

}
