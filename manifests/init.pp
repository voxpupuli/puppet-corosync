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
# [*threads*]
#   How many threads you are going to let corosync use to encode and decode
#   multicast messages.  If you turn off secauth then corosync wil ignore
#   threads.
#
# [*bind_address*]
#   The ip address we are going to bind the corosync daemon too.
#
# [*port*]
#   The udp port that corosync will use to do its multcast communication.  Be
#   aware that corosync used this defined port plus minus one.
#
# [*multicast_address*]
#   An IP address that has been reserved for multicast traffic.  This is the
#   default way that Corosync accomplishes communication across the cluster.
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
  $enable_secauth     = 'UNSET',
  $authkey            = '/etc/puppet/ssl/certs/ca.pem',
  $threads            = 'UNSET',
  $port               = 'UNSET',
  $bind_address       = 'UNSET',
  $multicast_address  = 'UNSET'
) {

  # Making it possible to provide data with parameterized class declarations or
  # Console.
  $threads_real = $threads ? {
    'UNSET' => $::threads ? {
      undef   => '1',
      default => $::threads,
    },
    default => $threads,
  }

  $port_real = $port ? {
    'UNSET' => $::port ? {
      undef   => '5405',
      default => $::port,
    },
    default => $port,
  }

  $bind_address_real = $bind_address ? {
    'UNSET' => $::bind_address ? {
      undef   => $::ipaddress,
      default => $::bind_address,
    },
    default => $bind_address,
  }

  # We use an if here instead of a selector since we need to fail the catalog if
  # this value is provided.  This is emulating a required variable as defined in
  # parameterized class.
  if $multicast_address == 'UNSET' {
    if ! $::multicast_address {
      fail('You must provide a value for multicast_address')
    } else {
      $multicast_address_real = $::multicast_address
    }
  } else {
    $multicast_address_real = $multicast_address
  }

  if $enable_secauth == 'UNSET' {
    case $::enable_secauth {
      true:  { $enable_secauth_real = 'on' }
      false: { $enable_secauth_real = 'off' }
      undef:   { $enable_secauth_real = 'on' }
      '':      { $enable_secauth_real = 'on' }
      default: { validate_re($::enable_secauth, '^true$|^false$') }
    }
  } else {
      case $enable_secauth {
        true:   { $enable_secauth_real = 'on' }
        false:  { $enable_secauth_real = 'off' }
        default: { fail('The enable_secauth class parameter requires a true or false boolean') }
      }
  }

  # Using the Puppet infrastructure's ca as the authkey, this means any node in
  # Puppet can join the cluster.  Totally not ideal, going to come up with
  # something better.
  if $enable_secauth_real == 'on' {
    file { '/etc/corosync/authkey':
      ensure  => file,
      source  => $authkey,
      mode    => '0400',
      owner   => 'root',
      group   => 'root',
      notify  => Service['corosync'],
    }
  }

  package { [ 'corosync', 'pacemaker' ]: ensure => present }

  file { '/etc/corosync/corosync.conf':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/corosync.conf.erb"),
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

  file { '/usr/lib/ocf/resource.d/pacemaker/ppk':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/ppk",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['pacemaker', 'corosync'],
    before  => Service['corosync'],
  }

  file { '/usr/lib/ocf/resource.d/pacemaker/ppdata':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/ppdata",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['pacemaker', 'corosync'],
    before  => Service['corosync'],
  }

  exec { 'enable corosync':
    command => 'sed -i s/START=no/START=yes/ /etc/default/corosync',
    path    => [ '/bin', '/usr/bin' ],
    unless  => 'grep START=yes /etc/default/corosync',
    require => Package['corosync'],
    before  => Service['corosync'],
  }

  service { 'corosync':
    ensure    => running,
    enable    => true,
    subscribe => File[ [ '/etc/corosync/corosync.conf', '/etc/corosync/service.d' ] ],
  }
}
