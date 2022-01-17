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
# @param multicast_address
#   An IP address that has been reserved for multicast traffic.  This is the
#   default way that Corosync accomplishes communication across the cluster.
#   Use 'broadcast' to have broadcast instead
#   Can be specified as an array to have multiple rings (multicast only).
#
# @param unicast_addresses
#   An array of IP addresses that make up the cluster's members.  These are
#   used if you are not able to use multicast on your network and instead opt
#   for the udpu transport. You need a relatively recent version of Corosync to
#   make this possible.
#   You can also have an array of arrays to have multiple rings. In that case,
#   each subarray matches a host IP addresses.
#   As of Corosync 3 knet is the new default which also does not use multicast.
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
# @param package_pacemaker
#   Define if package pacemaker should be managed.
#
# @param package_fence_agents
#   Define if package fence-agents should be managed.
#   Default (Red Hat based):  true
#   Default (otherwise):      false
#
# @param packageopts_corosync
#   Additional install-options for the corosync package resource.
#   Default:      undef
#
# @param packageopts_crmsh
#   Additional install-options for the crmsh package resource.
#   Default:      undef
#
# @param packageopts_pacemaker
#   Additional install-options for the pacemaker package resource.
#   Default:      undef
#
# @param packageopts_pcs
#   Additional install-options for the pcs package resource.
#   Default:      undef
#
# @param packageopts_fence_agents
#   Additional install-options for the pcs package resource.
#   Default:      undef
#
# @param ensure_corosync
#   Define what version of the corosync package should be installed.
#   Default: 'present'
#
# @param ensure_crmsh
#   Define what version of the crmsh package should be installed.
#   Default: 'present'
#
# @param ensure_pacemaker
#   Define what version of the pacemaker package should be installed.
#   Default: 'present'
#
# @param ensure_pcs
#   Define what version of the pcs package should be installed.
#   Default: 'present'
#
# @param ensure_fence_agents
#   Define what version of the fence-agents-all package should be installed.
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
#   corosync service. pcsd service is the GUI and the remote configuration
#   interface.
#
# @param manage_pcsd_auth
#   This only has an effect when $manage_pcsd_service is enabled. If set, an
#   attempt will be made to authorize pcs on the cluster node determined by
#   manage_pcsd_auth_node. Note that this determination can only be made when
#   the entries in quorum_members match the trusted certnames of the nodes in
#   the environment or the IP addresses of the primary adapters.
#   $sensitive_hacluster_password is mandatory if this parameter is set.
#
# @param manage_pcsd_auth_node
#   When managing authorization for PCS this determines which node does the
#   work. Note that only one node 'should' do the work and nodes are chosen by
#   matching local facts to the contents of quorum_members. When
#   manage_pcsd_auth is disabled this parameter has no effect.
#
# @param sensitive_hacluster_password
#   When PCS is configured on a RHEL system this directive is used to set the
#   password for the hacluster user. If both $manage_pcsd_service and
#   $manage_pcsd_auth are both set to true the cluster will use this credential
#   to authorize all nodes.
#
# @param sensitive_hacluster_hash
#   This parameter expects a valid password hash of
#   sensitive_hacluster_password. If provided, the hash provided the hash will
#   be used to set the password for the hacluster user on each node.
#
# @param manage_quorum_device
#   Enable or disable the addition of a quorum device external to the cluster.
#   This device is used avoid cluster splits typically in conjunction with
#   fencing by providing an external network vote. Additionally, this allows
#   symmentric clusters to continue operation in the event that 50% of their
#   nodes have failed.
#
# @param quorum_device_host
#   The fully qualified hostname of the quorum device. This parameter is
#   mandatory when manage_quorum_device is true.
#
# @param quorum_device_algorithm
#   There are currently two algorithms the quorum device can utilize to
#   determine how its vote should be allocated; Fifty-fifty split and
#   last-man-standing. See the
#   [corosync-qdevice man page](https://www.systutorials.com/docs/linux/man/8-corosync-qdevice/)
#   for details.
#
# @param package_quorum_device
#   The name of the package providing the quorum device functionality. This
#   parameter is mandatory if manage_quorum_device is true.
#
# @param sensitive_quorum_device_password
#   The plain text password for the hacluster user on the quorum_device_host.
#   This parameter is mandatory if manage_quorum_device is true.
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
# @param ip_version
#   This specifies version of IP to ask DNS resolver for.  The value can be
#   one of ipv4 (look only for an IPv4 address) , ipv6 (check only IPv6 address),
#   ipv4-6 (look for all address families and use first IPv4 address found in the
#   list if there is such address, otherwise use first IPv6 address) and
#   ipv6-4 (look for all address families and use first IPv6 address found in the
#   list if there is such address, otherwise use first IPv4 address).
#
#   Default (if unspecified) is ipv6-4 for knet and udpu transports and ipv4 for udp.
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
#
# @param test_corosync_config_cmd
#   Override the standard config_validate_cmd which only works for corosync 2.x.
#
# @param watchdog_device
#   Watchdog device to use, for example '/dev/watchdog' or 'off'.
#   Its presence (or lack thereof) shifted with corosync versions.
#
# @param provider
#   What command line utility provides corosync configuration capabilities.
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
class corosync (
  Boolean $enable_secauth                                               = $corosync::params::enable_secauth,
  Enum['file', 'string'] $authkey_source                                = $corosync::params::authkey_source,
  Variant[Stdlib::Filesource,Stdlib::Base64] $authkey                   = $corosync::params::authkey,
  Corosync::CryptoHash $crypto_hash                                     = 'sha1',
  Corosync::CryptoCipher $crypto_cipher                                 = 'aes256',
  Optional[Integer] $threads                                            = undef,
  Optional[Variant[Stdlib::Port, Array[Stdlib::Port]]] $port            = $corosync::params::port,
  Corosync::IpStringIp $bind_address                                    = $corosync::params::bind_address,
  Optional[Corosync::IpStringIp] $multicast_address                     = undef,
  Optional[Array] $unicast_addresses                                    = undef,
  Boolean $force_online                                                 = $corosync::params::force_online,
  Boolean $check_standby                                                = $corosync::params::check_standby,
  Boolean $log_timestamp                                                = $corosync::params::log_timestamp,
  Boolean $log_file                                                     = $corosync::params::log_file,
  Optional[Stdlib::Absolutepath] $log_file_name                         = undef,
  Boolean $debug                                                        = $corosync::params::debug,
  Boolean $log_stderr                                                   = $corosync::params::log_stderr,
  Corosync::SyslogPriority $syslog_priority                             = $corosync::params::syslog_priority,
  Boolean $log_function_name                                            = $corosync::params::log_function_name,
  Optional[Enum['none', 'active', 'passive']] $rrp_mode                 = undef,
  Optional[Integer] $netmtu                                             = undef,
  Optional[Integer[0,255]] $ttl                                         = undef,
  Optional[Enum['ykd', 'none']] $vsftype                                = undef,
  Boolean $package_corosync                                             = $corosync::params::package_corosync,
  Boolean $package_pacemaker                                            = $corosync::params::package_pacemaker,
  Boolean $package_fence_agents                                         = false,
  Optional[Array[String[1]]] $packageopts_corosync                      = $corosync::params::package_install_options,
  Optional[Array[String[1]]] $packageopts_pacemaker                     = $corosync::params::package_install_options,
  Optional[Array[String[1]]] $packageopts_crmsh                         = $corosync::params::package_install_options,
  Optional[Array[String[1]]] $packageopts_pcs                           = $corosync::params::package_install_options,
  Optional[Array[String[1]]] $packageopts_fence_agents                  = $corosync::params::package_install_options,
  String[1] $ensure_corosync                                            = $corosync::params::ensure_corosync,
  String[1] $ensure_crmsh                                               = $corosync::params::ensure_crmsh,
  String[1] $ensure_pacemaker                                           = $corosync::params::ensure_pacemaker,
  String[1] $ensure_pcs                                                 = $corosync::params::ensure_pcs,
  String[1] $ensure_fence_agents                                        = $corosync::params::ensure_fence_agents,
  Boolean $set_votequorum                                               = $corosync::params::set_votequorum,
  Optional[Integer] $votequorum_expected_votes                          = undef,
  Array $quorum_members                                                 = ['localhost'],
  Optional[Array] $quorum_members_ids                                   = undef,
  Optional[Array] $quorum_members_names                                 = undef,
  Optional[Integer] $token                                              = undef,
  Optional[Integer] $token_retransmits_before_loss_const                = undef,
  Optional[String] $compatibility                                       = undef,
  Boolean $enable_corosync_service                                      = $corosync::params::enable_corosync_service,
  Boolean $manage_corosync_service                                      = $corosync::params::manage_corosync_service,
  Boolean $enable_pacemaker_service                                     = $corosync::params::enable_pacemaker_service,
  Boolean $manage_pacemaker_service                                     = $corosync::params::manage_pacemaker_service,
  Boolean $enable_pcsd_service                                          = $corosync::params::enable_pcsd_service,
  Boolean $manage_pcsd_service                                          = false,
  Boolean $manage_pcsd_auth                                             = false,
  Optional[Sensitive[String]] $sensitive_hacluster_password             = undef,
  Optional[Sensitive[String]] $sensitive_hacluster_hash                 = undef,
  Enum['first','last'] $manage_pcsd_auth_node                           = 'first',
  Boolean $manage_quorum_device                                         = false,
  Optional[Stdlib::Fqdn] $quorum_device_host                            = undef,
  Corosync::QuorumAlgorithm $quorum_device_algorithm                    = 'ffsplit',
  Optional[String] $package_quorum_device                               = $corosync::params::package_quorum_device,
  Optional[Sensitive[String]] $sensitive_quorum_device_password         = undef,
  Optional[String[1]] $cluster_name                                     = undef,
  Optional[Integer] $join                                               = undef,
  Optional[Integer] $consensus                                          = undef,
  Optional[String[1]] $ip_version                                       = undef,
  Optional[Enum['yes', 'no']] $clear_node_high_bit                      = undef,
  Optional[Integer] $max_messages                                       = undef,
  String[1] $config_validate_cmd                                        = '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t',
  Boolean $test_corosync_config                                         = $corosync::params::test_corosync_config,
  Optional[Variant[Stdlib::Absolutepath, Enum['off']]] $watchdog_device = undef,
  Enum['pcs', 'crm'] $provider                                          = 'pcs',
  String $pcs_version                                                   = '', # lint:ignore:params_empty_string_assignment
) inherits corosync::params {
  if $set_votequorum and (empty($quorum_members) and empty($multicast_address) and !$cluster_name) {
    fail('set_votequorum is true, so you must set either quorum_members, or one of multicast_address or cluster_name.')
  }

  if $quorum_members_names and empty($quorum_members) {
    fail('quorum_members_names may not be used without the quorum_members.')
  }

  if $quorum_members_ids and empty($quorum_members) {
    fail('quorum_members_ids may not be used without the quorum_members.')
  }

  if $package_corosync {
    package { 'corosync':
      ensure          => $ensure_corosync,
      install_options => $packageopts_corosync,
    }
    $corosync_package_require = Package['corosync']
  } else {
    $corosync_package_require = undef
  }

  if $manage_corosync_service {
    $corosync_service_dependency = Service['corosync']
  } else {
    $corosync_service_dependency = undef
  }

  if $package_pacemaker {
    package { 'pacemaker':
      ensure          => $ensure_pacemaker,
      install_options => $packageopts_pacemaker,
    }
  }

  case $provider {
    'crm': {
      package { 'crmsh':
        ensure          => $ensure_crmsh,
        install_options => $packageopts_crmsh,
      }
    }
    'pcs': {
      package { 'pcs':
        ensure          => $ensure_pcs,
        install_options => $packageopts_pcs,
      }
      if $sensitive_hacluster_hash {
        group { 'haclient':
          ensure  => 'present',
          require => Package['pcs'],
        }

        user { 'hacluster':
          ensure   => 'present',
          gid      => 'haclient',
          password => $sensitive_hacluster_hash.unwrap,
        }
      }
    }
    default: {
      fail("Unknown corosync provider ${provider}")
    }
  }

  if $package_fence_agents {
    package { 'fence-agents-all':
      ensure          => $ensure_fence_agents,
      install_options => $packageopts_fence_agents,
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
          notify  => $corosync_service_dependency,
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
          notify  => $corosync_service_dependency,
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

    # Validate the pcs auth / qdevice parameters when both are enabled
    if $manage_pcsd_auth and $manage_quorum_device {
      # Ensure the optional parameters have been provided
      if ! $quorum_device_host {
        fail('The quorum device host must be specified!')
      }

      if ! $sensitive_quorum_device_password {
        fail('The password for the hacluster user on the quorum device node is mandatory!')
      }

      if ! $cluster_name {
        fail('A cluster name must be specified when a quorm device is configured!')
      }

      # The quorum device cannot be a member of the cluster!
      if $quorum_device_host in $quorum_members {
        fail('Quorum device host cannot also be a member of the cluster!')
      }
    } elsif $manage_pcsd_auth {
      if ! $sensitive_hacluster_password or ! $sensitive_hacluster_hash {
        fail('The hacluster password and hash must be provided to authorize nodes via pcsd.')
      }
    }

    # Determine if this node should perform authorizations
    case $manage_pcsd_auth_node {
      'first': { $auth_node = $quorum_members[0] }
      'last': { $auth_node = $quorum_members[length($quorum_members)-1] }
      default: {}
    }

    # Calculate a full list of IP addresses
    unless(empty($facts['networking']['interfaces'])) {
      $interface_ip_list = $facts['networking']['interfaces'].map |$entry| {
        if 'ip' in $entry[1] {
          $entry[1]['ip']
        } else {
          'no_address'
        }
      }
    } else {
      $interface_ip_list = []
    }

    # If the local data matches auth_node (hostname or primary IP) we can
    # perform auth processing for subsequent components
    if $trusted['certname'] == $auth_node
    or $trusted['hostname'] == $auth_node
    or $auth_node == $facts['networking']['ip']
    or $auth_node in $interface_ip_list {
      $is_auth_node = true
    } else {
      $is_auth_node = false
    }

    $exec_path = '/sbin:/bin:/usr/sbin:/usr/bin'

    if $manage_pcsd_auth and $is_auth_node {
      # TODO - verify if this breaks out of the sensitivity
      $hacluster_password = $sensitive_hacluster_password.unwrap
      $auth_credential_string = "-u hacluster -p ${hacluster_password}"

      # As the auth can happen before corosync.conf exists we need to explicitly
      # list the members to join.
      # TODO - verify that this is safe when quorum_members is a list of IP
      # addresses
      $node_string = join($quorum_members, ' ')

      # Define the pcs host command, this changed with 0.10.0 as per #513
      $pcs_auth_command = versioncmp($pcs_version, '0.10.0') ? {
        -1      => 'pcs cluster auth',
        default => 'pcs host auth',
      }

      # Attempt to authorize all members. The command will return successfully
      # if they were already authenticated so it's safe to run every time this
      # is applied.
      # TODO - make it run only once
      exec { 'authorize_members':
        command => "${pcs_auth_command} ${node_string} ${auth_credential_string}",
        path    => $exec_path,
        require => [
          Service['pcsd'],
          User['hacluster'],
        ],
      }
    }

    if $manage_quorum_device and $manage_pcsd_auth and $set_votequorum {
      package { $package_quorum_device:
        ensure          => 'present',
        install_options => $packageopts_corosync,
      }
      service { 'corosync-qdevice':
        ensure    => running,
        enable    => true,
        require   => Package[$package_quorum_device],
        subscribe => $corosync_service_dependency,
      }
    }

    if $manage_quorum_device and $manage_pcsd_auth and $is_auth_node and $set_votequorum {
      $pcs_cluster_setup_namearg = versioncmp($pcs_version, '0.10.0') ? {
        -1      => '--name',
        default => '',
      }
      # If the cluster hasn't been configured yet, temporarily configure it so
      # the Authorize qdevice command doesn't fail. This should generate
      # a temporary corosync.conf which will then be overwritten
      exec { 'pcs_cluster_temporary':
        command => "pcs cluster setup --force ${pcs_cluster_setup_namearg} ${cluster_name} ${node_string}",
        path    => $exec_path,
        onlyif  => 'test ! -f /etc/corosync/corosync.conf',
        require => Exec['authorize_members'],
      }
      # We need to do this so the temporary cluster doesn't delete our authkey
      if $enable_secauth {
        Exec['pcs_cluster_temporary'] -> File['/etc/corosync/authkey']
      }

      # Authorize the quorum device via PCS so we can execute the configuration
      $token_prefix = 'test 0 -ne $(grep'
      $token_suffix = '/var/lib/pcsd/tokens >/dev/null 2>&1; echo $?)'
      $qdevice_token_check = "${token_prefix} ${quorum_device_host} ${token_suffix}"

      $quorum_device_password = $sensitive_quorum_device_password.unwrap
      exec { 'authorize_qdevice':
        command => "${pcs_auth_command} ${quorum_device_host} -u hacluster -p ${quorum_device_password}",
        path    => $exec_path,
        onlyif  => $qdevice_token_check,
        require => [
          Package[$package_quorum_device],
          Exec['authorize_members'],
          Exec['pcs_cluster_temporary'],
        ],
      }

      # Add the quorum device to the cluster
      $quorum_host = "host=${quorum_device_host}"
      $quorum_algorithm = "algorithm=${quorum_device_algorithm}"
      $quorum_setup_cmd =
        "pcs quorum device add model net ${quorum_host} ${quorum_algorithm}"
      exec { 'pcs_cluster_add_qdevice':
        command => $quorum_setup_cmd,
        path    => $exec_path,
        onlyif  => [
          'test 0 -ne $(pcs quorum config | grep "host:" >/dev/null 2>&1; echo $?)',
        ],
        require => Exec['authorize_qdevice'],
        before  => File['/etc/corosync/corosync.conf'],
        notify  => Service['corosync-qdevice'],
      }
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
  # - $crypto_hash
  # - $crypto_cipher
  # - $threads
  # - $token
  # - $join
  # - $consensus
  # - $ip_version
  # - $clear_node_high_bit
  # - $max_messages
  if $test_corosync_config {
    $_config_validate_cmd = $config_validate_cmd
  } else {
    $_config_validate_cmd = undef
  }

  file { '/etc/corosync/corosync.conf':
    ensure       => file,
    mode         => '0644',
    owner        => 'root',
    group        => 'root',
    content      => template("${module_name}/corosync.conf.erb"),
    validate_cmd => $_config_validate_cmd,
    require      => $corosync_package_require,
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

  case $facts['os']['family'] {
    'Debian': {
      augeas { 'enable corosync':
        lens    => 'Shellvars.lns',
        incl    => '/etc/default/corosync',
        context => '/files/etc/default/corosync',
        changes => [
          'set START "yes"',
        ],
        require => $corosync_package_require,
        before  => $corosync_service_dependency,
      }
    }
    default: {}
  }

  if $check_standby {
    # Throws a puppet error if node is on standby
    exec { 'check_standby node':
      command => 'echo "Node appears to be on standby" && false',
      path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      onlyif  => "crm node status|grep ${facts['networking']['hostname']}-standby|grep 'value=\"on\"'",
      require => $corosync_service_dependency,
    }
  }

  if $force_online {
    exec { 'force_online node':
      command => 'crm node online',
      path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      onlyif  => "crm node status|grep ${facts['networking']['hostname']}-standby|grep 'value=\"on\"'",
      require => $corosync_service_dependency,
    }
  }

  if $manage_pacemaker_service {
    service { 'pacemaker':
      ensure     => running,
      enable     => $enable_pacemaker_service,
      hasrestart => true,
      subscribe  => $corosync_service_dependency,
    }
  }

  if $manage_corosync_service {
    service { 'corosync':
      ensure    => running,
      enable    => $enable_corosync_service,
      subscribe => File[['/etc/corosync/corosync.conf', '/etc/corosync/service.d']],
    }
  }
}
