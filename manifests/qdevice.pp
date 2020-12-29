# This class performs the configuration of the qdevice daemon on a target node.
# Note that this requires corosync 2.x and must never be deployed on a node
# which is actually part of a cluster. Additionally, you will need to open the
# correct firewall ports for both pcs, and the actual quorum device as shown in
# the included example.
#
# @param sensitive_hacluster_hash
#   The password hash for the hacluster user on this quorum device node. If
#   omitted, you must create the hacluster user and haclient group yourself.
#   This user is required  because pcsd must be used to perform the
#   quorum node configuration.
#
# @param package_pcs
#   Name of the PCS package on this system.
#
# @param package_corosync_qnetd
#   Name of the corosync qnetd package for this system.
#
# @param provider
#   What command line utility provides corosync configuration capabilities.
#
# @summary Performs basic initial configuration of the qdevice daemon on a node.
#
# @example Quorum node with default password & configuring the firewall
#   include firewalld
#
#   class { 'corosync::qdevice':
#     sensitive_hacluster_hash => $sensitive_hacluster_hash,
#   }
#   contain 'corosync::qdevice'
#
#   # Open the corosync-qnetd port
#   firewalld::custom_service { 'corosync-qdevice-net':
#     description => 'Corosync Quorum Net Device Port',
#     port        => [
#       {
#         port     => '5403',
#         protocol => 'tcp',
#       },
#     ],
#   }
#   firewalld_service { 'corosync-qdevice-net':
#     ensure  => 'present',
#     service => 'corosync-qdevice-net',
#     zone    => 'public',
#   }
#
#   # Configure general PCS firewall rules
#   firewalld_service { 'high-availability':
#     ensure  => 'present',
#     service => 'high-availability',
#     zone    => 'public',
#   }
#
# @see https://www.systutorials.com/docs/linux/man/8-corosync-qnetd/
class corosync::qdevice (
  String $provider,
  String[1] $package_pcs                                = 'pcs',
  String[1] $package_corosync_qnetd                     = 'corosync-qnetd',
  Optional[Sensitive[String]] $sensitive_hacluster_hash = undef,
) {
  case $provider {
    'pcs': {
      $cluster_group = 'haclient'
      $cluster_user = 'hacluster'

      # Install the required packages
      [$package_pcs, $package_corosync_qnetd].each |$package| {
        package { $package:
          ensure => present,
        }
      }

      if $sensitive_hacluster_hash {
        # Cluster control group
        group { $cluster_group:
          ensure  => 'present',
          require => Package[$package_pcs, $package_corosync_qnetd],
        }

        # Cluster admin credentials
        user { $cluster_user:
          ensure   => 'present',
          password => $sensitive_hacluster_hash.unwrap,
          gid      => $cluster_group,
        }
      }

      # Enable the PCS service
      service { 'pcsd':
        ensure  => 'running',
        enable  => true,
        require => [
          Package[$package_pcs],
          Package[$package_corosync_qnetd],
        ],
      }

      $exec_path = '/sbin:/bin:/usr/sbin:/usr/bin'

      # Configure the quorum device
      exec { 'pcs qdevice setup model net --enable --start':
        path    => $exec_path,
        onlyif  => [
          'test ! -f /etc/corosync/qnetd/nssdb/qnetd-cacert.crt',
        ],
        require => Service['pcsd'],
      }

      # Ensure the net device is running
      exec { 'pcs qdevice start net':
        path    => $exec_path,
        onlyif  => [
          'test -f /etc/corosync/qnetd/nssdb/qnetd-cacert.crt',
          'test 0 -ne $(pcs qdevice status net >/dev/null 2>&1; echo $?)',
        ],
        require => [
          Package['pcs'],
          Package['corosync-qnetd'],
        ],
      }
    }
    default: {
      fail("qdevice not supported by this module with provider ${provider}")
    }
  }
}
