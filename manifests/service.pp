# @summary Declare services within /etc/corosync/service.d/ (Corosync 1.x)
#
# Models a Corosync service.  Corosync services are plugins that provide
# functionality for monitoring cluster resources.  One of the most common
# of these plugins being Pacemaker. This is for corosync 1.x!
#
# @param name [String]
#   The namevar in this type is the title you give it when you define a resource
#   instance.  It is used for a handful of purposes; defining the name of the
#   config file and the name defined inside the file itself.
#
# @param version
#   Version of the protocol used by this service. This is currently unused.
#
#
# @example Simple configuration of a service with version '0'.
#
#   corosync::service { 'pacemaker':
#     version => '0',
#   }
#
# === Authors
#
# Cody Herriges <cody@puppetlabs.com>
#
# === Copyright
#
# Copyright 2012 Puppet Labs, LLC.
#
define corosync::service (
  String[1] $version,
) {
  file { "/etc/corosync/service.d/${name}":
    ensure  => file,
    content => template("${module_name}/service.erb"),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['corosync'],
    notify  => Service['corosync'],
  }
}
