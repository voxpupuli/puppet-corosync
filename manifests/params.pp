# Class corosync::params
#
# This class manages corosync parameters
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#

class corosync::params {
    $enable_secauth     = 'UNSET'
    $threads            = 'UNSET'
    $port               = 'UNSET'
    $bind_address       = 'UNSET'
    $multicast_address  = 'UNSET'
    $unicast_addresses  = 'UNSET'
    $force_online       = false
    $check_standby      = false
    $debug              = false
    $corosync_dir       = '/etc/corosync'
    $conf_file          = "${corosync_dir}/corosync.conf"
    $corosync_svc_dir   = "${corosync_dir}/service.d"
    $service_enable     = true

    if $::osfamily == 'suse' {
        $authkey        = '/var/lib/puppet/ssl/certs/ca.pem'
        $corosync_name  = 'corosync'
        $corosync_svc   = 'openais'
        $pacemaker      = 'pacemaker'
    }
    elsif $::osfamily == 'debian' {
        $authkey        = '/etc/puppet/ssl/certs/ca.pem'
        $corosync_name  = 'corosync'
        $corosync_svc   = '$corosync_name'
        $pacemaker      = 'pacemaker'
    }
    else {
        fail("Class['corosync::params']: Unsupported operatingsystem: $operatingsystem")
    }
}
