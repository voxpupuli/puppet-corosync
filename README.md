# Puppet module for Corosync & Pacemaker

[![License](https://img.shields.io/github/license/voxpupuli/puppet-corosync.svg)](https://github.com/voxpupuli/puppet-corosync/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/voxpupuli/puppet-corosync.svg?branch=master)](https://travis-ci.org/voxpupuli/puppet-corosync)
[![Code Coverage](https://coveralls.io/repos/github/voxpupuli/puppet-corosync/badge.svg?branch=master)](https://coveralls.io/github/voxpupuli/puppet-corosync)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/corosync.svg)](https://forge.puppetlabs.com/puppet/corosync)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/corosync.svg)](https://forge.puppetlabs.com/puppet/corosync)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/corosync.svg)](https://forge.puppetlabs.com/puppet/corosync)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/corosync.svg)](https://forge.puppetlabs.com/puppet/corosync)
-[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/533/badge)](https://bestpractices.coreinfrastructure.org/projects/533)

The [clusterlabs][cl] stack incorporates Corosync and Pacemaker in an
Open-Source, High Availability stack for both small and large deployments.

It supports a lot of different HA setups and is very flexible.

This puppet module is suitable for the management of both the software stack
(pacemaker and corosync) and the cluster resources (via puppet types and
providers).

*Note:* This module is the successor of *puppetlabs-corosync*.

[cl]:http://clusterlabs.org/

## Documentation

### Basic usage

*To install and configure Corosync*

```puppet
class { 'corosync':
  authkey        => '/var/lib/puppet/ssl/certs/ca.pem',
  bind_address   => $facts['networking']['ip'],
  cluster_name   => 'mycluster',
  enable_secauth => true,
}
```

*To enable Pacemaker*

```puppet
corosync::service { 'pacemaker':
  version => '0',
}
```
*To configure advanced and (very) verbose logging settings*

```puppet
class { 'corosync':
  log_stderr        => false,
  log_function_name => true,
  syslog_priority   => 'debug',
  debug             => true,
}
```

*To disable Corosync and Pacemaker services*

```puppet
class { 'corosync':
  enable_corosync_service  => false,
  enable_pacemaker_service => false,
}
```

### Configure Corosync Secure Authentication

By default the built-in Puppet CA will be used to perform this authentication,
however, generating a dedicated key is a better approach.

1. Generate a new key on a machine with Corosync installed and convert it to Base64.

    ```bash
    # Generate the key
    corosync-keygen -k /tmp/authkey
    ```
2. Convert the key file to a Base64 string so it can be used in your manifest.

    ```bash
    # Convert it to a Base64 string
    base64 -w 0 /tmp/authkey > /tmp/authkey_base64
    ```
3. Declare the corosync module using this string.

    ```puppet
    class { 'corosync':
      enable_secauth => true,
      authkey_source => 'string',
      authkey        => 'MxjvpEztT3Mi+QagUO2cefhLDrP2BSFYKS3g1WXTUj2eCgGDPcSNf3uCKgzJKhoWTgJm2nYDHJv8KiFqMoW3ATuVr/9fLb/lgUVfoz0GnP10S7r77aqaIsERhJcGVQhcteHVlZl6zOo6VQz4ekH7VPmMlKJX0iQPuJTh9o6qhjg=',
    }
    ```

If the authkey is included directly in config, consider storing the value in hiera and encrypting it via [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml).

### PCSD Authorization

The pacemaker/corosync configuration system (pcs) includes a daemon (pcsd) which can be configured to perform distributed communication across the cluster. This is accomplished by establishing token-based authorization of each cluster node via the `pcs auth` command.

On systems which support it, management of PCS authorization can be configured and deployed via this module as shown in the following example:

```puppet
class { 'corosync':
  manage_pcsd_service          => true,
  manage_pcsd_auth             => true,
  sensitive_hacluster_password => Sensitive('this-is-the-actual-password'),
  sensitive_hacluster_hash     => Sensitive('a-hash-of-the-passwd-for-the-user-resource'),
}
```

Note that as this must only be executed on one node and by default the 'first' node in the cluster list is used. There may be timing issues if the configuration has not yet been applied on the other nodes as a successful execution requires the password for hacluster to be appropriately set on each system.

### Configure votequorum

*To enable Corosync 2 votequorum and define a nodelist
of nodes named n1, n2, n3 with auto generated node IDs*

```puppet
class { 'corosync':
  set_votequorum => true,
  quorum_members => [ 'n1', 'n2', 'n3' ],
}
```

*To do the same but with custom node IDs instead*
```puppet
class { 'corosync':
  set_votequorum     => true,
  quorum_members     => [ 'n1', 'n2', 'n3' ],
  quorum_members_ids => [ 10, 11, 12 ],
}
```

Note: custom IDs may be required when adding or removing
nodes to a cluster on a fly. Then each node shall have an
unique and persistent ID.

*To have multiple rings in the nodelist*
```puppet
class { 'corosync':
  set_votequorum     => true,
  quorum_members     => [
    ['172.31.110.1', '172.31.111.1'],
    ['172.31.110.2', '172.31.111.2'],
  ],
}
```

When `quorum_members` is an array of arrays, each sub array represents one
host IP addresses.

#### Configure a Quorum Device (corosync-qdevice)

Recent versions of corosync include support for a network based quorum device that is external to the cluster. This provides tiebreaker functionality to clusters with even node counts allowing 2-node or higher clusters which can operate with exactly half of their nodes to function. There are two components to quorum device configuration:

* A node which is not a member of any Corosync cluster will host the corosync-qnet daemon. This node should be outside of the network containing the cluster nodes.
* Each member of the cluster will be authorized to communicate with the quorum node and have the corosync-qdevice service scheduled and operating.

This implementation depends entirely on [PCSD authorization](#pcsd-authorization) and will only execute with that enabled.

1. Configure the qdevice class on the quorum node. Note that the same quorum node can be used for multiple clusters. Additionally, this node **cannot be a normal cluster member**!

    ```puppet
    # In this example, the node's name is quorum1.test.org
    class { 'corosync::qdevice':
      sensitive_hacluster_hash => Sensitive('hash-of-haclusters-password-on-the-qdevice-node')
    }
    ```
2. Configure and enable qdevice settings on the cluster members via the corosync main class.

    ```puppet
    class { 'corosync':
      cluster_name                     => 'example',
      manage_pcsd_service              => true,
      manage_pcsd_auth                 => true,
      sensitive_hacluster_password     => Sensitive('this-is-the-actual-password'),
      sensitive_hacluster_hash         => Sensitive('a-hash-of-the-passwd-for-the-user-resource'),
      manage_quorum_device             => true,
      quorum_device_host               => 'quorum1.test.org',
      quorum_device_algorithm          => 'ffsplit',
      sensitive_quorum_device_password => Sensitive('Actual password for hacluster on quorum1.test.org'),
    }
    ```

For more information see the following:

* [RedHat High Availability Add-On - 10.5 Quorum Devices](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/high_availability_add-on_reference/s1-quorumdev-haar)
* [corosync-qdevice Man Page](https://www.systutorials.com/docs/linux/man/8-corosync-qdevice/)

### Configuring primitives

The resources that Corosync will manage can be referred to as a primitive.
These are things like virtual IPs or services like drbd, nginx, and apache.

*To assign a VIP to a network interface to be used by Nginx*

```puppet
cs_primitive { 'nginx_vip':
  primitive_class => 'ocf',
  primitive_type  => 'IPaddr2',
  provided_by     => 'heartbeat',
  parameters      => { 'ip' => '172.16.210.100', 'cidr_netmask' => '24' },
  operations      => { 'monitor' => { 'interval' => '10s' } },
}
```

*Make Corosync manage and monitor the state of Nginx using a custom OCF agent*

```puppet
cs_primitive { 'nginx_service':
  primitive_class => 'ocf',
  primitive_type  => 'nginx_fixed',
  provided_by     => 'pacemaker',
  operations      => {
    'monitor'     => { 'interval' => '10s', 'timeout' => '30s' },
    'start'       => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
  },
  require         => Cs_primitive['nginx_vip'],
}
```

*Make Corosync manage and monitor the state of Apache using a LSB agent*

```puppet
cs_primitive { 'apache_service':
  primitive_class => 'lsb',
  primitive_type  => 'apache2',
  provided_by     => 'heartbeat',
  operations      => {
    'monitor'     => { 'interval' => '10s', 'timeout' => '30s' },
    'start'       => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' }
  },
  require         => Cs_primitive['apache2_vip'],
}
```

Note: If you have multiple operations with the same names, you have to use an array.
Example:
```puppet
cs_primitive { 'pgsql_service':
  primitive_class => 'ocf',
  primitive_type  => 'pgsql',
  provided_by     => 'heartbeat',
  operations      => [
    { 'monitor'   => { 'interval' => '10s', 'timeout' => '30s' } },
    { 'monitor'   => { 'interval' => '5s', 'timeout' => '30s' 'role' => 'Master', } },
    { 'start'     => { 'interval' => '0', 'timeout' => '30s', 'on-fail' => 'restart' } }
  ],
}
```

If you do mot want Puppet to interfere with manually stopped resources
(e.g not change the `target-role` metaparameter), you can use the
`unmanaged_metadata` parameter:

```puppet
cs_primitive { 'pgsql_service':
  primitive_class    => 'ocf',
  primitive_type     => 'pgsql',
  provided_by        => 'heartbeat',
  unmanaged_metadata => ['target-role'],
}
```

### Configuring STONITH Resources

Special primitives can be configured to support [STONITH (Shoot The Other Node In The Head)](https://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/1.1/html-single/Pacemaker_Explained/index.html#_what_is_stonith) fencing. This is critical for clusters which include shared resources (shared disk typically) or are vulnerable to cluster splits. The STONITH resource is responsible for providing a mechanism to restart or simply halt a rouge resource, often via power fencing.

The following example performs this configuration via the *fence_vmware_soap* STONITH agent.

```puppet
cs_primitive { 'vmfence':
  primitive_class => 'stonith',
  primitive_type  => 'fence_vmware_soap',
  operations      => {
    'monitor'     => { 'interval' => '60s'},
  },
  parameters      => {
    'ipaddr'          => 'vcenter.example.org',
    'login'           => 'service-fence@vsphere.local'
    'passwd'          => 'some plaintext secret',
    'ssl'             => '1',
    'ssl_insecure'    => '1',
    'pcmk_host_map'   => 'host0.example.org:host0;host1.example.org:host1',
    'pcmk_delay_max'  => '10s',
  },
}
```

Note that currently this implementation only handles STONITH for RHEL/CentOS based clusters which utilize `pcs`.

### Configuring locations

Locations determine on which nodes primitive resources run.

```puppet
cs_location { 'nginx_service_location':
  primitive => 'nginx_service',
  node_name => 'hostname',
  score     => 'INFINITY'
}
```

To manage rule on a location.
Example to force the location to not run on a container (VM).

```puppet
cs_location { 'nginx_service_location':
  primitive => 'nginx_service',
  rules     => [
    { 'nginx-service-avoid-container-rule' => {
        'score'      => '-INFINITY',
        'expression' => [
          { 'attribute' => '#kind',
            'operation' => 'eq',
            'value'     => 'container'
          },
        ],
      },
    },
  ],
}
```

Example of a virtual ip location that checks ping connectivity for placement.

```puppet
cs_location { 'vip-ping-connected':
  primitive => 'vip',
  rules     => [
    { 'vip-ping-exclude-rule' => {
        'score'      => '-INFINITY',
        'expression' => [
          { 'attribute' => 'pingd',
            'operation' => 'lt',
            'value'     => '100',
          },
        ],
      },
    },
    { 'vip-ping-prefer-rule' => {
        'score-attribute' => 'pingd',
        'expression'      => [
          { 'attribute' => 'pingd',
            'operation' => 'defined',
          }
        ],
      },
    },
  ],
}
```

Example of another possibility to use ping connectivity for placement.

```puppet
cs_location { 'vip-ping-connected':
  primitive => 'vip',
  rules     => [
    { 'vip-ping-connected-rule' => {
        'score'      => '-INFINITY',
        'boolean-op' => 'or',
        'expression' => [
          { 'attribute' => 'pingd',
            'operation' => 'not_defined',
          },
          { 'attribute' => 'pingd',
            'operation' => 'lte',
            'value'     => '100',
          },
        ],
      },
    },
  ],
}
```

### Configuring colocations

Colocations keep primitives together.  Meaning if a vip moves to web02 from web01
because web01 just hit the dirt it will drag the nginx service with it.

```puppet
cs_colocation { 'vip_with_service':
  primitives => [ 'nginx_vip', 'nginx_service' ],
}
```

*pcs only* Advanced colocations are also possible with colocation sets by using
arrays instead of strings in the primitives array. Additionally, a hash can be
added to the inner array with the specific options for that resource set.

```puppet
cs_colocation { 'mysql_and_ptheartbeat':
  primitives => [
    ['mysql', {'role' => 'master'}],
    [ 'ptheartbeat' ],
  ],
}
```

```puppet
cs_colocation { 'mysql_apache_munin_and_ptheartbeat':
  primitives => [
    ['mysql', 'apache', {'role' => 'master'}],
    [ 'munin', 'ptheartbeat' ],
  ],
}
```

### Configuring migration or state order

Colocation defines that a set of primitives must live together on the same node
but order definitions will define the order of which each primitive is started.  If
Nginx is configured to listen only on our vip we definitely want the vip to be
migrated to a new node before nginx comes up or the migration will fail.

```puppet
cs_order { 'vip_before_service':
  first   => 'nginx_vip',
  second  => 'nginx_service',
  require => Cs_colocation['vip_with_service'],
}
```

### Configuring cloned resources/groups

Cloned resources should be active on multiple hosts at the same time. You can
clone any existing resource provided the resource agent supports it.

```puppet
cs_clone { 'nginx_service-clone' :
  ensure    => present,
  primitive => 'nginx_service',
  clone_max => 3,
  require   => Cs_primitive['nginx_service'],
}
```

You can also clone groups:

```puppet
cs_clone { 'nginx_service-clone' :
  ensure    => present,
  group     => 'nginx_group',
  clone_max => 3,
  require   => Cs_primitive['nginx_service'],
}
```

Configure a Promotable (Active/Passive) resource

```puppet
cs_clone { 'redis-clone':
  ensure            => present,
  primitive         => 'redis',
  clone_max         => 2,
  clone_node_max    => 1,
  promotable        => true,
  promoted_max      => 1,
  promoted_node_max => 1,
  notify_clones     => true,
}
```

### Corosync Properties

A few global settings can be changed with the "cs_property" section.

Disable STONITH if required.
```puppet
cs_property { 'stonith-enabled' :
  value   => 'false',
}
```

Change quorum policy
```puppet
cs_property { 'no-quorum-policy' :
  value   => 'ignore',
}
```

You can use the replace parameter to create but not update some values:

```puppet
cs_property { 'maintenance-mode':
  value   => 'true',
  replace => false,
}
```

### Resource defaults

A few global settings can be changed with the "cs_rsc_defaults" section.

Don't move resources.
```puppet
cs_rsc_defaults { 'resource-stickiness' :
  value => 'INFINITY',
}
```

### Multiple rings

In unicast mode, you can have multiple rings by specifying unicast_address and
bind_address as arrays:

```puppet
class { 'corosync':
  enable_secauth    => true,
  authkey           => '/var/lib/puppet/ssl/certs/ca.pem',
  bind_address      => ['10.0.0.1', '10.0.1.1'],
  unicast_addresses => [
      [ '10.0.0.1',
        '10.0.1.1'
      ], [
        '10.0.0.2',
        '10.0.1.2'
      ],
  ],
}
```

The unicast_addresses is an array of arrays. One sub array matches one host
IP addresses. In this example host2 has IP addresses 10.0.0.2 and 10.0.1.2.

### Shadow CIB

Shadow CIB allows you to apply all the changes at the same time. For that, you
need to use the `cib` parameter and the `cs_commit` and `cs_shadow` types.

Shadow CIB is *the* recommended way to manage large CIB with puppet, as it will
apply all your changes at once, starting the cluster when everything is in
place: primitives, constraints, properties.

If you set the `cib` parameter to one `cs_*` resource we recommend you to set
that `cib` parameter to all the `cs_*` resources.


```puppet
cs_shadow {
    'puppet':
}
cs_primitive { 'pgsql_service':
  primitive_class => 'ocf',
  primitive_type  => 'pgsql',
  provided_by     => 'heartbeat',
  cib             => 'puppet'
}
cs_commit {
    'puppet':
}
```

## Notes

### Upstream documentation
We suggest you at least go read the [Clusters from Scratch](http://clusterlabs.org/pacemaker/doc/) document
from Cluster Labs.  It will help you out a lot when understanding how all the pieces
fall together a point you in the right direction when Corosync/Pacemaker fails unexpectedly.

### Roadmap

We do maintain a [roadmap regarding next releases of this module](ROADMAP.md).

### Operating System support matrix

| OS          | release | Puppet 3.8.7  | Puppet 4 (PC1)   | Puppet 5.X       |
|-------------|---------|---------------|------------------|------------------|
| CentOS/RHEL | 7       | Not supported | **Supported**    | **Supported**    |
| Debian      | 9       | Not supported | **Supported**    | **Supported**    |
| Ubuntu      | 16.04   | Not supported | **Supported**    | **Supported**    |

## Contributors

[See Github](https://github.com/voxpupuli/puppet-corosync/graphs/contributors).

Special thanks to [Puppet, Inc](http://puppet.com) for initial development and
[Vox Pupuli](https://voxpupuli.org) to provide a platform that allows us to
continue the development of this module.

## Development

See the [contributing guide](.github/CONTRIBUTING.md) for details. Additionally, some general guidelines on PR structure can be found [here](https://voxpupuli.org/docs/#reviewing-a-module-pr).

## Copyright and License

Copyright © 2012-2014 [Puppet Inc](https://www.puppet.com/)

Copyright © 2012-2018 [Multiple contributors][mc]

[mc]:https://github.com/voxpupuli/puppet-corosync/graphs/contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
