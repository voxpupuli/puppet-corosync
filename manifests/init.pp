# @summary Configures the Pacemaker+Corosync stack to provide high-availability.
#
# This class will set up corosync for use by the Puppet Enterprise console to
# facilitate an active/standby configuration for high availability.  It is
# assumed that this module has been initially ran on a Puppet master with the
# capabilities of signing certificates to do the initial key generation.
#
# @param enable_secauth
#   Controls corosync's ability to authenticate and encrypt multicast messages.
#
# @param secauth_parameter_mode
#   Determines whether the crypto_hash and crypto_cipher parameters are
#   specified. These flags were added in Corosync 2.x so operating systems using
#   older 1.x packages must continue to use sec_auth instead.
#
# @param authkey_source
#   Allows to use either a file or a string as a authkey.
#
# @param authkey
#   Specifies the path to the CA which is used to sign Corosync's certificate if
#   authkey_source is 'file' or a base64 encoded version of the actual authkey
#   if 'string' is used instead.
#
# @param crypto_hash
#   Hashing algorithm used by corosync for intra-cluster communication. Valid
#   values are none, md5, sha1, sha256, sha384, and sha512
#
# @param crypto_cipher
#   Encryption cipher used by corosync for intra-cluster communication. Valid
#   values are none, aes256, aes192, aes128, and 3des
#
# @param threads
#   How many threads you are going to let corosync use to encode and decode
#   multicast messages.  If you turn off secauth then corosync will ignore
#   threads.
#
# @param bind_address
#   The ip address we are going to bind the corosync daemon too.
#   Can be specified as an array to have multiple rings.
#
# @param port
#   The UDP port that corosync will use to do its multicast communication. Be
#   aware that corosync used this defined port plus minus one.
#   Can be specified as an array to have multiple rings.
#
# @param multicast_address [Optional[Stdlib::Compat::Ip_address]]
#   An IP address that has been reserved for multicast traffic.  This is the
#   default way that Corosync accomplishes communication across the cluster.
#   Use 'broadcast' to have broadcast instead
#   Can be specified as an array to have multiple rings (multicast only).
#
# @param unicast_addresses
#   An array of IP addresses that make up the cluster's members.  These are
#   use if you are able to use multicast on your network and instead opt for
#   the udpu transport.  You need a relatively recent version of Corosync to
#   make this possible.
#   You can also have an array of arrays to have multiple rings. In that case,
#   each subarray matches a host IP addresses.
#
# @param force_online
#   Boolean parameter specifying whether to force nodes that have been put
#   in standby back online.
#
# @param check_standby
#   Boolean parameter specifying whether puppet should return an error log
#   message if a node is in standby. Useful for monitoring node state.
#
# @param log_timestamp
#   Boolean parameter specifying whether a timestamp should be placed on all
#   log messages.
#
# @param log_file
#   Boolean parameter specifying whether Corosync should produce debug
#   output in a logfile.
#
# @param log_file_name
#   Absolute path to the logfile Corosync should use when `$log_file` (see
#   above) is true.
#
# @param debug
#   Boolean parameter specifying whether Corosync should produce debug
#   output in its logs.
#
# @param log_stderr
#   Boolean parameter specifying whether Corosync should log errors to
#   stderr.
#
# @param syslog_priority
#   String parameter specifying the minimal log level for Corosync syslog
#   messages. Allowed values: debug|info|notice|warning|err|emerg.
#
# @param log_function_name
#   Boolean parameter specifying whether Corosync should log called function
#   names to.
#
# @param rrp_mode
#   Mode of redundant ring. May be none, active, or passive.
#
# @param netmtu
#   This specifies the network maximum transmit unit.
#
# @param ttl
#   Time To Live.
#
# @param vsftype
#   Virtual synchrony filter type.
#
# @param package_corosync
#   Define if package corosync should be managed.
#
# @param package_crmsh
#   Define if package crmsh should be managed.
#   Default (Debian based): true
#   Default (otherwise):    false
#
# @param package_pacemaker
#   Define if package pacemaker should be managed.
#
# @param package_pcs
#   Define if package pcs should be managed.
#   Default (Red Hat based):  true
#   Default (otherwise):      false
#
# @param packageopts_corosync
#   Additional install-options for the corosync package resource.
#   Default (Debian Jessie):  ['-t', 'jessie-backports']
#   Default (otherwise):      undef
#
# @param packageopts_crmsh
#   Additional install-options for the crmsh package resource.
#   Default (Debian Jessie):  ['-t', 'jessie-backports']
#   Default (otherwise):      undef
#
# @param packageopts_pacemaker
#   Additional install-options for the pacemaker package resource.
#   Default (Debian Jessie):  ['-t', 'jessie-backports']
#   Default (otherwise):      undef
#
# @param packageopts_pcs
#   Additional install-options for the pcs package resource.
#   Default (Debian Jessie):  ['-t', 'jessie-backports']
#   Default (otherwise):      undef
#
# @param version_corosync
#   Define what version of the corosync package should be installed.
#   Default: 'present'
#
# @param version_crmsh
#   Define what version of the crmsh package should be installed.
#   Default: 'present'
#
# @param version_pacemaker
#   Define what version of the pacemaker package should be installed.
#   Default: 'present'
#
# @param version_pcs
#   Define what version of the pcs package should be installed.
#   Default: 'present'
#
# @param set_votequorum
#   Set to true if corosync_votequorum should be used as quorum provider.
#   Default (Red Hat based):    true
#   Default (Ubuntu >= 14.04):  true
#   Default (otherwise):        false
#
# @param votequorum_expected_votes
#   Overrides the automatic calculation of expected votes which is normally
#   derived from the number of nodes.
#
# @param quorum_members
#   Array of quorum member hostname. This is required if set_votequorum
#   is set to true.
#   You can also have an array of arrays to have multiple rings. In that case,
#   each subarray matches a member IP addresses.
#
# @param quorum_members_ids
#   Array of quorum member IDs. Persistent IDs are required for the dynamic
#   config of a corosync cluster and when_set_votequorum is set to true.
#   Should be used only with the quorum_members parameter.
#
# @param quorum_members_names
#   Array of quorum member names. Persistent names are required when you
#   define IP addresses in quorum_members.
#
# @param token
#   Time (in ms) to wait for a token
#
# @param token_retransmits_before_loss_const
#   How many token retransmits before forming a new configuration.
#
# @param compatibility
#   Older versions of corosync allowed a config-file directive to indicate
#   backward compatibility. This sets that.
#
# @param enable_corosync_service
#   Whether the module should enable the corosync service.
#
# @param manage_corosync_service
#   Whether the module should try to manage the corosync service. If set to
#   false, the service will need to be specified in the catalog elsewhere.
#
# @param enable_pacemaker_service
#   Whether the module should enable the pacemaker service.
#
# @param manage_pacemaker_service
#   Whether the module should try to manage the pacemaker service.
#   Default (Red Hat based >= 7): true
#   Default (Ubuntu >= 14.04):    true
#   Default (otherwise):          false
#
# @param enable_pcsd_service
#   Whether the module should enable the pcsd service.
#
# @param manage_pcsd_service
#   Whether the module should try to manage the pcsd service in addition to the
#   corosync service.
#   pcsd service is the GUI and the remote configuration interface.
#
# @param cluster_name
#   This specifies the name of cluster and it's used for automatic
#   generating of multicast address.
#
# @param join
#   This timeout specifies in milliseconds how long to wait for join messages
#   in the membership protocol.
#
# @param consensus
#   This timeout specifies in milliseconds how long to wait for consensus to be
#   achieved before starting a new round of membership configuration.
#   The minimum value for consensus must be 1.2 * token. This value will be
#   automatically calculated at 1.2 * token if the user doesn't specify a
#   consensus value.
#
# @param clear_node_high_bit
#   This configuration option is optional and is only relevant when no nodeid
#   is specified. Some openais clients require a signed 32 bit nodeid that is
#   greater than zero however by default openais uses all 32 bits of the IPv4
#   address space when generating a nodeid. Set this option to yes to force
#   the high bit to be zero and therefor ensure the nodeid is a positive signed
#   32 bit integer.
#   WARNING: The clusters behavior is undefined if this option is enabled on
#   only a subset of the cluster (for example during a rolling upgrade).
#
# @param max_messages
#   This constant specifies the maximum number of messages that may be sent by
#   one processor on receipt of the token. The max_messages parameter is limited
#   to 256000 / netmtu to prevent overflow of the kernel transmit buffers.
#
# @param test_corosync_config
#   Whether we should test new configuration files with `corosync -t`.
#   (requires corosync 2.3.4)
#   Default (Red Hat based >= 7): true
#   Default (Ubuntu >= 16.04):    true
#   Default (Debian >= 8):        true
#   Default (otherwise):          false
#
# @example Simple configuration without secauth
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
  Boolean $enable_secauth                                            = $corosync::params::enable_secauth,
  Enum['1.x','2.x'] $secauth_parameter_mode                          = $corosync::params::secauth_parameter_mode,
  Enum['file', 'string'] $authkey_source                             = $corosync::params::authkey_source,
  Variant[Stdlib::Absolutepath,Stdlib::Base64] $authkey              = $corosync::params::authkey,
  Corosync::CryptoHash $crypto_hash                                  = 'sha1',
  Corosync::CryptoCipher $crypto_cipher                              = 'aes256',
  Optional[Integer] $threads                                         = undef,
  Optional[Variant[Integer[0,65535], Array[Integer[0,65535]]]] $port = $corosync::params::port,
  Corosync::IpStringIp $bind_address                                 = $corosync::params::bind_address,
  Optional[Stdlib::Compat::Ip_address] $multicast_address            = undef,
  Optional[Array] $unicast_addresses                                 = undef,
  Boolean $force_online                                              = $corosync::params::force_online,
  Boolean $check_standby                                             = $corosync::params::check_standby,
  Boolean $log_timestamp                                             = $corosync::params::log_timestamp,
  Boolean $log_file                                                  = $corosync::params::log_file,
  Optional[Stdlib::Absolutepath] $log_file_name                      = undef,
  Boolean $debug                                                     = $corosync::params::debug,
  Boolean $log_stderr                                                = $corosync::params::log_stderr,
  Corosync::SyslogPriority $syslog_priority                          = $corosync::params::syslog_priority,
  Boolean $log_function_name                                         = $corosync::params::log_function_name,
  Optional[Enum['none', 'active', 'passive']] $rrp_mode              = undef,
  Optional[Integer] $netmtu                                          = undef,
  Optional[Integer[0,255]] $ttl                                      = undef,
  Optional[Enum['ykd', 'none']] $vsftype                             = undef,
  Boolean $package_corosync                                          = $corosync::params::package_corosync,
  Boolean $package_crmsh                                             = $corosync::params::package_crmsh,
  Boolean $package_pacemaker                                         = $corosync::params::package_pacemaker,
  Boolean $package_pcs                                               = $corosync::params::package_pcs,
  Optional[Array] $packageopts_corosync                              = $corosync::params::package_install_options,
  Optional[Array] $packageopts_pacemaker                             = $corosync::params::package_install_options,
  Optional[Array] $packageopts_crmsh                                 = $corosync::params::package_install_options,
  Optional[Array] $packageopts_pcs                                   = $corosync::params::package_install_options,
  String $version_corosync                                           = $corosync::params::version_corosync,
  String $version_crmsh                                              = $corosync::params::version_crmsh,
  String $version_pacemaker                                          = $corosync::params::version_pacemaker,
  String $version_pcs                                                = $corosync::params::version_pcs,
  Boolean $set_votequorum                                            = $corosync::params::set_votequorum,
  Optional[Integer] $votequorum_expected_votes                       = undef,
  Array $quorum_members                                              = ['localhost'],
  Optional[Array] $quorum_members_ids                                = undef,
  Optional[Array] $quorum_members_names                              = undef,
  Optional[Integer] $token                                           = undef,
  Optional[Integer] $token_retransmits_before_loss_const             = undef,
  Optional[String] $compatibility                                    = undef,
  Boolean $enable_corosync_service                                   = $corosync::params::enable_corosync_service,
  Boolean $manage_corosync_service                                   = $corosync::params::manage_corosync_service,
  Boolean $enable_pacemaker_service                                  = $corosync::params::enable_pacemaker_service,
  Boolean $manage_pacemaker_service                                  = $corosync::params::manage_pacemaker_service,
  Boolean $enable_pcsd_service                                       = $corosync::params::enable_pcsd_service,
  Boolean $manage_pcsd_service                                       = false,
  Optional[String] $cluster_name                                     = undef,
  Optional[Integer] $join                                            = undef,
  Optional[Integer] $consensus                                       = undef,
  Optional[Enum['yes', 'no']] $clear_node_high_bit                   = undef,
  Optional[Integer] $max_messages                                    = undef,
  Boolean $test_corosync_config                                      = $corosync::params::test_corosync_config,
) inherits ::corosync::params {

  if $set_votequorum and empty($quorum_members) {
    fail('set_votequorum is true, but no quorum_members have been passed.')
  }

  if $quorum_members_names and empty($quorum_members) {
    fail('quorum_members_names may not be used without the quorum_members.')
  }

  if $quorum_members_ids and empty($quorum_members) {
    fail('quorum_members_ids may not be used without the quorum_members.')
  }

  if $package_corosync {
    package { 'corosync':
      ensure          => $version_corosync,
      install_options => $packageopts_corosync,
    }
    $corosync_package_require = Package['corosync']
  } else {
    $corosync_package_require = undef
  }

  if $package_pacemaker {
    package { 'pacemaker':
      ensure          => $version_pacemaker,
      install_options => $packageopts_pacemaker,
    }
  }

  if $package_crmsh {
    package { 'crmsh':
      ensure          => $version_crmsh,
      install_options => $packageopts_crmsh,
    }
  }

  if $package_pcs {
    package { 'pcs':
      ensure          => $version_pcs,
      install_options => $packageopts_pcs,
    }
  }

  # You have to specify at least one of the following parameters:
  # $multicast_address or $unicast_address or $cluster_name
  if !$multicast_address and empty($unicast_addresses) and !$cluster_name {
      fail('You must provide a value for multicast_address, unicast_address or cluster_name.')
  }

  # Using the Puppet infrastructure's ca as the authkey, this means any node in
  # Puppet can join the cluster.  Totally not ideal, going to come up with
  # something better.
  if $enable_secauth {
    case $authkey_source {
      'file': {
        file { '/etc/corosync/authkey':
          ensure  => file,
          source  => $authkey,
          mode    => '0400',
          owner   => 'root',
          group   => 'root',
          notify  => Service['corosync'],
          require => $corosync_package_require,
        }
        File['/etc/corosync/authkey'] -> File['/etc/corosync/corosync.conf']
      }
      'string': {
        file { '/etc/corosync/authkey':
          ensure  => file,
          content => Binary($authkey, '%B'),
          mode    => '0400',
          owner   => 'root',
          group   => 'root',
          notify  => Service['corosync'],
          require => $corosync_package_require,
        }
        File['/etc/corosync/authkey'] -> File['/etc/corosync/corosync.conf']
      }
      default: {}
    }
  }

  if $manage_pcsd_service {
    service { 'pcsd':
      ensure  => running,
      enable  => $enable_pcsd_service,
      require => Package['pcs'],
    }
  }

  # Template uses:
  # - $unicast_addresses
  # - $multicast_address
  # - $cluster_name
  # - $log_timestamp
  # - $log_file
  # - $log_file_name
  # - $debug
  # - $bind_address
  # - $port
  # - $enable_secauth
  # - $threads
  # - $token
  # - $join
  # - $consensus
  # - $clear_node_high_bit
  # - $max_messages
  if $test_corosync_config {
    # corosync -t is only included since 2.3.4
    file { '/etc/corosync/corosync.conf':
      ensure       => file,
      mode         => '0644',
      owner        => 'root',
      group        => 'root',
      content      => template("${module_name}/corosync.conf.erb"),
      validate_cmd => '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t',
      require      => $corosync_package_require,
    }
  } else {
    file { '/etc/corosync/corosync.conf':
      ensure  => file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template("${module_name}/corosync.conf.erb"),
      require => $corosync_package_require,
    }
  }

  file { '/etc/corosync/service.d':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    recurse => true,
    purge   => true,
    require => $corosync_package_require,
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
        require => $corosync_package_require,
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
      enable     => $enable_pacemaker_service,
      hasrestart => true,
      subscribe  => Service['corosync'],
    }
  }

  if $manage_corosync_service {
    service { 'corosync':
      ensure    => running,
      enable    => $enable_corosync_service,
      subscribe => File[ [ '/etc/corosync/corosync.conf', '/etc/corosync/service.d' ] ],
    }
  }
}
