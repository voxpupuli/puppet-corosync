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
# [*log_stderr*]
#   True/false parameter specifying whether Corosync should log errors to
#   stderr. Defaults to True.
#
# [*syslog_priority*]
#   String parameter specifying the minimal log level for Corosync syslog
#   messages. Allowed values: debug|info|notice|warning|err|emerg.
#   Defaults to 'info'.
#
# [*log_function_name*]
#   True/false parameter specifying whether Corosync should log called funcions
#   names to. Defaults to False.
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
#   Defaults to true on RedHat based operating systems.
#   Defaults to true on Ubuntu version 14.04 or greater.
#   Defaults to false on all other operating systems.
#
# [*quorum_members*]
#   Array of quorum member hostname. This is required if set_votequorum
#   is set to true.
#   Defaults to ['localhost']
#
# [*quorum_members_ids*]                                                                                                                                                                  #   Array of quorum member IDs. Persistent IDs are required for the dynamic
#   config of a corosync cluster and when_set_votequorum is set to true.
#   Should be used only with the quorum_members parameter.
#   Defaults to undef
#
# [*token*]
#   Time (in ms) to wait for a token
#
# [*token_retransmits_before_loss_const*]
#   How many token retransmits before forming a new configuration
#
# [*manage_pacemaker_service*]
#   Whether the module should try to manage the pacemaker service in
#   addition to the corosync service.
#   Defaults to false, except on Ubuntu 14.04+ where it defaults to true.
#
# [*manage_pcsd_service*]
#   Whether the module should try to manage the pcsd service in addition to the
#   corosync service.
#   pcsd service is the GUI and the remote configuration interface.
#   Defaults to false
#
# [*cluster_name*]
#   This specifies the name of cluster and it's used for automatic
#   generating of multicast address.
#
# [*join*]
#   This timeout specifies in milliseconds how long to wait for join messages
#   in the membership protocol.
#   Default to 50
#
# [*consensus*]
#   This timeout specifies in milliseconds how long to wait for consensus to be
#   achieved before starting a new round of membership configuration.
#   The minimum value for consensus must be 1.2 * token. This value will be
#   automatically calculated at 1.2 * token if the user doesn't specify a
#   consensus value.
#   Defaults to false,
#
# [*max_messages*]
#   This constant specifies the maximum number of messages that may be sent by
#   one processor on receipt of the token. The max_messages parameter is limited
#   to 256000 / netmtu to prevent overflow of the kernel transmit buffers.
#   Defaults to 17
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
  $log_stderr                          = $::corosync::params::log_stderr,
  $syslog_priority                     = $::corosync::params::syslog_priority,
  $log_function_name                   = $::corosync::params::log_function_name,
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
  $votequorum_expected_votes           = $::corosync::params::votequorum_expected_votes,
  $quorum_members                      = ['localhost'],
  $quorum_members_ids                  = undef,
  $token                               = $::corosync::params::token,
  $token_retransmits_before_loss_const = $::corosync::params::token_retransmits_before_lost_const,
  $compatibility                       = $::corosync::params::compatibility,
  $manage_pacemaker_service            = $::corosync::params::manage_pacemaker_service,
  $manage_pcsd_service                 = false,
  $cluster_name                        = $::corosync::params::cluster_name,
  $join                                = $::corosync::params::join,
  $consensus                           = $::corosync::params::consensus,
  $max_messages                        = $::corosync::params::max_messages,
) inherits ::corosync::params {

  if $set_votequorum and !$quorum_members {
    fail('set_votequorum is true, but no quorum_members have been passed.')
  }

  if $quorum_members_ids and !$quorum_members {
    fail('quorum_members_ids may not be used without the quorum_members.')
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
  validate_bool($log_stderr)
  validate_re($syslog_priority, '^(debug|info|notice|warning|err|emerg)$')
  validate_bool($log_function_name)

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
      if $manage_pcsd_service {
        service { 'pcsd':
          ensure  => running,
          enable  => true,
          require => Package['pcs'],
        }
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
  # - $join
  # - $consensus
  # - $max_messages
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
    require => Package['corosync'],
  }

  case $::osfamily {
    'Debian': {
      augeas { 'enable corosync':
        lens    => 'Shellvars.lns',
        incl    => '/etc/default/corosync',
        context => '/files/etc/default/corosync',
        changes => [
          'set START "yes"',
        ],
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

  if $manage_pacemaker_service {
    service { 'pacemaker':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      subscribe  => Service['corosync'],
    }
  }

  service { 'corosync':
    ensure    => running,
    enable    => true,
    subscribe => File[ [ '/etc/corosync/corosync.conf', '/etc/corosync/service.d' ] ],
  }
}
