# == Define: corosync::service
#
# Models a corosync service for use by the Puppet Enterprise Console.
#
# === Parameters
#
# [*namevar*]
#   If there is a parameter that defaults to the value of the title string
#   when not explicitly set, you must always say so.  This parameter can be
#   referred to as a "namevar," since it's functionally equivalent to the
#   namevar of a core resource type.
#
# [*version*]
#   Version of the protocol used by this service.
#
# === Examples
#
# Provide some examples on how to use this type:
#
#   hapec::corosync::service { 'pacemaker':
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
define corosync::service($version) {

  file { "/etc/corosync/service.d/${name}":
    ensure  => file,
    content => template("${module_name}/service.erb"),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }
}
