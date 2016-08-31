# Public Roadmap

## voxpupuli-corosync v5.0.0

- Minimum Puppet version: 3.8.0
- Long Term Support release
- General code optimization and cleanup
- Branched off to a "puppet 3 branch"
- PR [#291](https://github.com/voxpupuli/puppet-corosync/pull/291)

### Puppet 3 support

The 5.0.0 release will be a LTS and will be supported until VoxPupuli stops
Puppet 3 support (voxpupuli/plumbing#21). It will be the latest release to
support Puppet 3. After its release, only bugfixes and security fixes will be
applied. We will not introduce backward incompatible changes in this LTS
release.

That LTS release will be available under the "puppet3" branch of this module.

Please consider moving straight to Puppet 4.

## voxpupuli-corosync v6.0.0

- Minimum required version: Puppet 4.6.
- Cleanup Puppet 3 related code
- Use Puppet 4 features
- drop params.pp in favour of Puppet 4 mechanism
- Use Puppet Types for every parameter
- Close discussions around the name of this module (and maybe rename it)
  ([#32](https://github.com/voxpupuli/puppet-corosync/issues/32))

### Cleanup old distributions

The module currently supports Ubuntu 14.04, 16.04, Debian Jessie and EL7
distributions. In v6.0.0 we will remove all the references to any other
distributions.

In the meantime, we will be happy to welcome pull requests if you want to fix
or add support for any other distribution.

### Naming of this module

The issue [#32](https://github.com/voxpupuli/puppet-corosync/issues/32)
concerning the naming of this module will be closed in three major releases
of this module. In v6.0.0, this module could be rebranded to a better name.

