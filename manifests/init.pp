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
# === Examples
#
#  class { 'hapec::corosync':
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
      'true':  { $enable_secauth_real = 'on' }
      'false': { $enable_secauth_real = 'off' }
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

  if $enable_secauth_real == 'on' {
    exec { 'corosync-key':
      command => 'puppet certificate generate --ca-location remote --config /etc/puppetlabs/puppet/puppet.conf pe-internal-corosync'
      path    => '/opt/puppet/bin:/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      creates => '/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-corosync.pem',
    }
    file { '/etc/corosync/authkey':
      ensure  => file,
      source  => $is_puppetmaster ? {
        true  => '/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-corosync.pem',
        false => undef,
      },
      content => $is_puppetmaster ? {
        true  => undef,
        false => file('/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-corosync.pem'),
      },
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

  service { 'corosync':
    ensure  => running,
    enable  => true,
    require => File['/etc/corosync/corosync.conf'],
  }
}
