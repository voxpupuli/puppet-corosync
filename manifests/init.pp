# == Class: corosync
#
# This class will set up corosync for use by the Puppet Enterprise console to
# facilitate an active/standby configuration for high availability.  It is
# assumed that this module has been initially ran on a Puppet master with the
# capabilities of signing certificates to do the initial key generation.
#
# === Parameters
#
# [*enable_secauth*]
#   Controls corosync's ability to authenticate and encrypt multicast messages.
#
# [*authkey_source*]
#   Allows to use either a file or a string as a authkey.
#   Defaults to 'file'. Can be set to 'string'.
#
# [*authkey*]
#   Specifies the path to the CA which is used to sign Corosync's certificate if
#   authkey_source is 'file' or the actual authkey if 'string' is used instead.
#
# [*threads*]
#   How many threads you are going to let corosync use to encode and decode
#   multicast messages.  If you turn off secauth then corosync wil ignore
#   threads.
#
# [*bind_address*]
#   The ip address we are going to bind the corosync daemon too.
#   Can be specified as an array to have multiple rings (multicast only).
#
# [*port*]
#   The udp port that corosync will use to do its multicast communication.  Be
#   aware that corosync used this defined port plus minus one.
#   Can be specified as an array to have multiple rings (multicast only).
#
# [*multicast_address*]
#   An IP address that has been reserved for multicast traffic.  This is the
#   default way that Corosync accomplishes communication across the cluster.
#   Use 'broadcast' to have broadcast instead
#   Can be specified as an array to have multiple rings (multicast only).
#
# [*unicast_addresses*]
#   An array of IP addresses that make up the cluster's members.  These are
#   use if you are able to use multicast on your network and instead opt for
#   the udpu transport.  You need a relatively recent version of Corosync to
#   make this possible.
#
# [*force_online*]
#   True/false parameter specifying whether to force nodes that have been put
#   in standby back online.
#
# [*check_standby*]
#   True/false parameter specifying whether puppet should return an error log
#   message if a node is in standby. Useful for monitoring node state.
#
# [*debug*]
#   True/false parameter specifying whether Corosync should produce debug
#   output in its logs.
#
# [*rrp_mode*]
#   Mode of redundant ring. May be none, active, or passive.
#
# [*ttl*]
#   Time To Live (multicast only).
#
# [*package_corosync*]
#   Define if package corosync should be installed.
#   Defaults to true
#
# [*version_corosync*]
#   Define what version of corosync should be installed.
#   Defaults to present
#
# [*package_pacemaker*]
#   Define if package pacemaker should be installed.
#   Defaults to true
#
# [*version_pacemaker*]
#   Define what version of pacemaker should be installed.
#   Defaults to present
#
# [*package_pcs*]
#   Define if package pcs should be installed.
#   Defaults to true
#
# [*version_pcs*]
#   Define what version of pcs should be installed.
#   Defaults to present
#
# [*set_votequorum*]
#   Set to true if corosync_votequorum should be used as quorum provider.
#   Defaults to false.
#
# [*quorum_members*]
#   Array of quorum member hostname. This is required if set_votequorum
#   is set to true.
#   Defaults to undef,
#
# [*token*]
#   Time (in ms) to wait for a token
#
# [*token_retransmits_before_loss_const*]
#   How many token retransmits before forming a new configuration
#
# === Deprecated Parameters
#
# [*packages*]
#   Deprecated in favour of package_{corosync,pacemaker} and
#   version_{corosync,pacemaker}. Array of packages to install.
#
# === Examples
#
#  class { 'corosync':
#    enable_secauth    => false,
#    bind_address      => '192.168.2.10',
#    multicast_address => '239.1.1.2',
#  }
#
# === Authors
#
# Cody Herriges <cody@puppetlabs.com>
#
# === Copyright
#
# Copyright 2012, Puppet Labs, LLC.
#
class corosync(
  $enable_secauth                      = $::corosync::params::enable_secauth,
  $authkey_source                      = $::corosync::params::authkey_source,
  $authkey                             = $::corosync::params::authkey,
  $threads                             = $::corosync::params::threads,
  $port                                = $::corosync::params::port,
  $bind_address                        = $::corosync::params::bind_address,
  $multicast_address                   = $::corosync::params::multicast_address,
  $unicast_addresses                   = $::corosync::params::unicast_addresses,
  $force_online                        = $::corosync::params::force_online,
  $check_standby                       = $::corosync::params::check_standby,
  $debug                               = $::corosync::params::debug,
  $rrp_mode                            = $::corosync::params::rrp_mode,
  $ttl                                 = $::corosync::params::ttl,
  $packages                            = undef,
  $package_corosync                    = undef,
  $version_corosync                    = undef,
  $package_pacemaker                   = undef,
  $version_pacemaker                   = undef,
  $package_pcs                         = undef,
  $version_pcs                         = undef,
  $set_votequorum                      = $::corosync::params::set_votequorum,
  $quorum_members                      = ['localhost'],
  $token                               = $::corosync::params::token,
  $token_retransmits_before_loss_const = $::corosync::params::token_retransmits_before_lost_const,
) inherits ::corosync::params {

  if $set_votequorum and !$quorum_members {
    fail('set_votequorum is true, but no quorum_members have been passed.')
  }

  if $packages {
    warning('$corosync::packages is deprecated, use $corosync::package_{corosync,pacemaker} instead!')

    package{ $packages:
      ensure => present,
    }

    # Ensure no options conflicting with $packages are set:

    if $package_corosync {
      fail('$corosync::package_corosync and $corosync::packages must not be mixed!')
    }
    if $package_pacemaker {
      fail('$corosync::package_pacemaker and $corosync::packages must not be mixed!')
    }
    if $version_corosync {
      fail('$corosync::version_corosync and $corosync::packages must not be mixed!')
    }
    if $version_pacemaker {
      fail('$corosync::version_pacemaker and $corosync::packages must not be mixed!')
    }
  } else {
      # Handle defaults for new-style package parameters here to allow co-existence with $packages.
      if $package_corosync == undef {
        $_package_corosync = true
      } else {
        $_package_corosync = $package_corosync
      }

      if $package_pacemaker == undef {
        $_package_pacemaker = true
      } else {
        $_package_pacemaker = $package_pacemaker
      }

      if $version_corosync == undef {
        $_version_corosync = present
      } else {
        $_version_corosync = $version_corosync
      }

      if $version_pacemaker == undef {
        $_version_pacemaker = present
      } else {
        $_version_pacemaker = $version_pacemaker
      }

      if $_package_corosync == true {
        package { 'corosync':
          ensure => $_version_corosync,
        }
      }

      if $_package_pacemaker == true {
        package { 'pacemaker':
          ensure => $_version_pacemaker,
        }
      }
    }

  if ! is_bool($enable_secauth) {
    validate_re($enable_secauth, '^(on|off)$')
  }
  validate_re($authkey_source, '^(file|string)$')
  validate_bool($force_online)
  validate_bool($check_standby)
  validate_bool($debug)

  if $unicast_addresses == 'UNSET' {
    $corosync_conf = "${module_name}/corosync.conf.erb"
  } else {
    $corosync_conf = "${module_name}/corosync.conf.udpu.erb"
  }

  # $multicast_address is NOT required if $unicast_address is provided
  if $multicast_address == 'UNSET' and $unicast_addresses == 'UNSET' {
      fail('You must provide a value for multicast_address')
  }

  case $enable_secauth {
    true:    { $enable_secauth_real = 'on' }
    false:   { $enable_secauth_real = 'off' }
    default: { $enable_secauth_real = $enable_secauth }
  }

  # Using the Puppet infrastructure's ca as the authkey, this means any node in
  # Puppet can join the cluster.  Totally not ideal, going to come up with
  # something better.
  if $enable_secauth_real == 'on' {
    case $authkey_source {
      'file': {
        file { '/etc/corosync/authkey':
          ensure  => file,
          source  => $authkey,
          mode    => '0400',
          owner   => 'root',
          group   => 'root',
          notify  => Service['corosync'],
          require => Package['corosync'],
        }
      }
      'string': {
        file { '/etc/corosync/authkey':
          ensure  => file,
          content => $authkey,
          mode    => '0400',
          owner   => 'root',
          group   => 'root',
          notify  => Service['corosync'],
          require => Package['corosync'],
        }
      }
      default: {}
    }
  }

  if $::osfamily == 'RedHat' {
    if $package_pcs == undef {
      $_package_pcs = true
    } else {
      $_package_pcs = $package_pcs
    }
  
    if $version_pcs == undef {
      $_version_pcs = present
    } else {
      $_version_pcs = $version_pcs
    }

    if $_package_pcs {
      package { 'pcs':
        ensure => $_version_pcs,
      }
    }
  }
  
  # Template uses:
  # - $unicast_addresses
  # - $multicast_address
  # - $debug
  # - $bind_address
  # - $port
  # - $enable_secauth_real
  # - $threads
  # - $token
  file { '/etc/corosync/corosync.conf':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template($corosync_conf),
    require => Package['corosync'],
  }

  file { '/etc/corosync/service.d':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    recurse => true,
    purge   => true,
    require => Package['corosync']
  }

  case $::osfamily {
    'Debian': {
      exec { 'enable corosync':
        command => 'sed -i s/START=no/START=yes/ /etc/default/corosync',
        path    => [ '/bin', '/usr/bin' ],
        unless  => 'grep START=yes /etc/default/corosync',
        require => Package['corosync'],
        before  => Service['corosync'],
      }
    }
    default: {}
  }

  if $check_standby {
    # Throws a puppet error if node is on standby
    exec { 'check_standby node':
      command => 'echo "Node appears to be on standby" && false',
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      onlyif  => "crm node status|grep ${::hostname}-standby|grep 'value=\"on\"'",
      require => Service['corosync'],
    }
  }

  if $force_online {
    exec { 'force_online node':
      command => 'crm node online',
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      onlyif  => "crm node status|grep ${::hostname}-standby|grep 'value=\"on\"'",
      require => Service['corosync'],
    }
  }

  service { 'corosync':
    ensure    => running,
    enable    => true,
    subscribe => File[ [ '/etc/corosync/corosync.conf', '/etc/corosync/service.d' ] ],
  }
}
