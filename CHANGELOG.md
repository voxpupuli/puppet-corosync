# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v6.0.1](https://github.com/voxpupuli/puppet-corosync/tree/v6.0.1) (2018-03-28)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v6.0.0...v6.0.1)

**Fixed bugs:**

- Cannot avoid the `bindnetaddr` to be set into `/etc/corosync/corosync.conf` file [\#421](https://github.com/voxpupuli/puppet-corosync/issues/421)
- fix output of clear\_node\_high\_bit variable in config [\#433](https://github.com/voxpupuli/puppet-corosync/pull/433) ([oveaurs](https://github.com/oveaurs))
- member section is deprecated in favor of nodelist [\#430](https://github.com/voxpupuli/puppet-corosync/pull/430) ([actatux](https://github.com/actatux))

**Closed issues:**

- Warning in generated corosync.conf [\#422](https://github.com/voxpupuli/puppet-corosync/issues/422)
- Could not autoload puppet/provider/cs\_property/pcs: [\#403](https://github.com/voxpupuli/puppet-corosync/issues/403)

**Merged pull requests:**

- bump puppet to latest supported version 4.10.0 [\#436](https://github.com/voxpupuli/puppet-corosync/pull/436) ([bastelfreak](https://github.com/bastelfreak))
- Use docker\_sets in travis.yml [\#435](https://github.com/voxpupuli/puppet-corosync/pull/435) ([ekohl](https://github.com/ekohl))

## [v6.0.0](https://github.com/voxpupuli/puppet-corosync/tree/v6.0.0) (2017-12-09)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v5.1.0...v6.0.0)

**Breaking changes:**

- Move away from the UNSET pattern [\#322](https://github.com/voxpupuli/puppet-corosync/issues/322)
- \[RFC\] Removing enable\_secauth\_real [\#420](https://github.com/voxpupuli/puppet-corosync/pull/420) ([kBite](https://github.com/kBite))
- Breaking: Use puppet4 data types [\#419](https://github.com/voxpupuli/puppet-corosync/pull/419) ([kBite](https://github.com/kBite))

**Implemented enhancements:**

- Support Debian 9 [\#404](https://github.com/voxpupuli/puppet-corosync/issues/404)
- support Debian 9 \(\#404\) [\#416](https://github.com/voxpupuli/puppet-corosync/pull/416) ([wyardley](https://github.com/wyardley))

**Fixed bugs:**

- added class param clear\_node\_high\_bit. This is used in templates/coro… [\#402](https://github.com/voxpupuli/puppet-corosync/pull/402) ([oveaurs](https://github.com/oveaurs))

**Merged pull requests:**

- Fix variable type to allow authkey to be a string [\#427](https://github.com/voxpupuli/puppet-corosync/pull/427) ([cedef](https://github.com/cedef))
- Added manage corosync feature [\#424](https://github.com/voxpupuli/puppet-corosync/pull/424) ([Nekototori](https://github.com/Nekototori))

## [v5.1.0](https://github.com/voxpupuli/puppet-corosync/tree/v5.1.0) (2017-10-27)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v5.0.0...v5.1.0)

**Implemented enhancements:**

- Define the names of the quorum members [\#407](https://github.com/voxpupuli/puppet-corosync/pull/407) ([actatux](https://github.com/actatux))
- Add tunables to enable the services [\#406](https://github.com/voxpupuli/puppet-corosync/pull/406) ([actatux](https://github.com/actatux))
- Add pcs provider for cs\_rsc\_defaults type [\#399](https://github.com/voxpupuli/puppet-corosync/pull/399) ([spacedog](https://github.com/spacedog))

**Fixed bugs:**

- CentOS 7 issues w/ pcs / CIB shadow [\#409](https://github.com/voxpupuli/puppet-corosync/issues/409)
- openhpid dependency issue [\#408](https://github.com/voxpupuli/puppet-corosync/issues/408)
- Change usage of CIB shadow for pcs [\#410](https://github.com/voxpupuli/puppet-corosync/pull/410) ([actatux](https://github.com/actatux))

**Closed issues:**

- Parameter 'log\_file\_name' is not processed [\#400](https://github.com/voxpupuli/puppet-corosync/issues/400)
- Cannot apply a cs\_location to a group of resources [\#396](https://github.com/voxpupuli/puppet-corosync/issues/396)
- cs\_group expecting more than 1 member [\#375](https://github.com/voxpupuli/puppet-corosync/issues/375)
- Vox Pupuli First Elections [\#355](https://github.com/voxpupuli/puppet-corosync/issues/355)

**Merged pull requests:**

- Simplify acceptance, allow hack for Debian 8 to return 1 or 100 [\#413](https://github.com/voxpupuli/puppet-corosync/pull/413) ([wyardley](https://github.com/wyardley))
- update badges and add tags to metadata [\#412](https://github.com/voxpupuli/puppet-corosync/pull/412) ([wyardley](https://github.com/wyardley))
- Configure debian 8 systems for acceptance tests [\#411](https://github.com/voxpupuli/puppet-corosync/pull/411) ([actatux](https://github.com/actatux))
- cs\_location should require cs\_group [\#397](https://github.com/voxpupuli/puppet-corosync/pull/397) ([roidelapluie](https://github.com/roidelapluie))
- Bump min version\_requirement for Puppet + dep [\#393](https://github.com/voxpupuli/puppet-corosync/pull/393) ([juniorsysadmin](https://github.com/juniorsysadmin))
- Support timestamp and logfile config options [\#389](https://github.com/voxpupuli/puppet-corosync/pull/389) ([antaflos](https://github.com/antaflos))
- Add CII badge [\#387](https://github.com/voxpupuli/puppet-corosync/pull/387) ([roidelapluie](https://github.com/roidelapluie))
- rubocop: fix RSpec/ImplicitExpect [\#386](https://github.com/voxpupuli/puppet-corosync/pull/386) ([alexjfisher](https://github.com/alexjfisher))
- Support configuring netmtu [\#384](https://github.com/voxpupuli/puppet-corosync/pull/384) ([trondiz](https://github.com/trondiz))
- Update crm.rb [\#383](https://github.com/voxpupuli/puppet-corosync/pull/383) ([VuokkoVuorinnen](https://github.com/VuokkoVuorinnen))
- Release 5.0.0 [\#373](https://github.com/voxpupuli/puppet-corosync/pull/373) ([roidelapluie](https://github.com/roidelapluie))

## v5.0.0 (2016-09-16)
- Allow multiple rings in nodelist (#262, #291, #336, #358)
- Add support for cs\_location rules (#132, #310, #356)
- Allow 1-element arrays for primitives in cs\_group (#152, #368)
- Add support for clone of groups (#176, #371)
- New class parameter: vsftype (#345)
- Add the nodelist to corosync.conf even if we set the expected votes count
  (#347)
- Add autorequirement between cs\_location and cs\_primitives/cs\_clone (#359)
- Add autorequirement between cs\_clone and cs\_primitive (#357, #365)
- Lots of fixes regarding cs\_clone (#367, #149, #370)
- Add "Managed By Puppet" header to corosync.conf (#360)
- Improve tests (#335, #337, #331, #328, #364, #369, #370)
- Modulesync (#330)

### Backward incompatible changes
- Support for Puppet < 3.8.0 is removed (#334)
- Logging to file is enabled by default. (#345)
- Corosync.conf got a major cleanup. Most of the parameters are now implicit so
  we get pacemaker defaults. List of affected parameters: compatibility,
  consensus, join, max\_messages, rrp\_mode, threads, token,
  token\_retransmits\_before\_loss\_const, vsftype.
  Those parameters can now be specified as class parameters. (#345)
- Removed legacy configuration sections: amf, aisexec, logging.logger\_subsys
  (#345)
- Fix two\_nodes behaviour with expected\_votes = 2 introduced in 3.0.0 (#246)
- Cs\_clone: clones are now stopped before being removed (crm provider) (#367)
- Cs\_clone now uses the resource name as clone id (pcs provider) (#149, #367)
- Cs\_clone purges parameters that are not explicitly set (#370)

### Deprecation notes

We have plans to rename this module and deprecated old Puppet releases and
Puppet distributions. Please refer to our [roadmap](ROADMAP.md) for further
details.

#### Naming of this module

The issue [#32](https://github.com/voxpupuli/puppet-corosync/issues/32)
concerning the naming of this module will be closed in the next major release
of this module. In v6.0.0, this module could be rebranded to a better name, as
well as the types and resources.

# 2016-09-02 - Release 4.0.1
### Summary
- Fix enable_secauth => false (#341)

# 2016-08-30 - Release 4.0.0
### Summary
- Validate corosync configuration before overwriting (available in EL7, Ubuntu
  16.04, and Debian Jessie) (#294)
- multicast\_address and unicast\_addresses are no longer mandatory if
  clustername is set (#318)
- Modulesync updates

### Backward incompatible changes
- Support for Puppet <= 3.6.0 is removed (#319)

### Deprecation notes

We have plans to rename this module and deprecated old Puppet releases and
Puppet distributions. Please refer to our [roadmap](ROADMAP.md) for further
details.

#### Naming of this module

The issue [#32](https://github.com/voxpupuli/puppet-corosync/issues/32)
concerning the naming of this module will be closed in two major releases
of this module. In v6.0.0, this module could be rebranded to a better name.

# 2016-08-18 - Release 3.0.0
### Summary
- Fixed a bug with two\_nodes option and three-node clusters (#316)
- Improved corosync readiness detection (#314)
- Modulesync updates
- Introduce a public [roadmap](ROADMAP.md)

### Backward incompatible changes
- Providers now wait up to 60 seconds to get a non null CIB. On new clusters, it
  means that you wait 60 seconds for nothing, but when adding a node to the
  cluster, it means that we join the cluster before operating it with this
  puppet module. If you are using Cs\_shadow and all your resources depend on
  that one, then instead of a non-null (non `0.0`) epoch, we wait for a non 
  `0.*` epoch, because the Cs\_shadow and Cs\_commit couple will update the
  epoch anyway. (#314)

### Deprecation notes

Deprecating old Puppet releases:

- We will remove support for Puppet <= 3.6.0 in the next major release of this
  module (v4.0.0).
- We will remove support for Puppet <= 3.8.0 in two major releases of this
  module (v5.0.0).
- We will remove support for Puppet <= 4.6.0 in three major releases of this
  module (v6.0.0).

#### Puppet 3 support

The 5.0.0 release will be a LTS and will be supported until VoxPupuli stops
Puppet 3 support (voxpupuli/plumbing#21). It will be the latest release to
support Puppet 3. After its release, only bugfixes and security fixes will be
applied. We will not introduce backward incompatible changes in this LTS
release.

That LTS release will be available under the "puppet3" branch of this module.

Please consider moving straight to Puppet 4.

#### Naming of this module

The issue [#32](https://github.com/voxpupuli/puppet-corosync/issues/32)
concerning the naming of this module will be closed in three major releases
of this module. In v6.0.0, this module could be rebranded to a better name.

## 2016-06-28 - Release 2.0.1
### Summary
- Support Ubuntu 16.04 (#288)
- Fix travis release (#302)

## 2016-06-28 - Release 2.0.0
### Summary
- Replace Cs\_primitive[manage\_target\_role] parameter by
  Cs\_primitive[unmanaged\_metadata] parameter (#275)
- Support Debian 8. Requires jessie-backports apt repository (not included in
  this module) (#282)
- Set Puppet requirement version to >= 3.0.0 < 5.0.0 (#286)
- Add a `cib` parameter to cs\_rsc\_default (#296)

### Backward incompatible changes
- Cs\_primitive[manage\_target\_role] parameter (introduced in 1.1.0, deprecated
  in 1.2.0) has ben replaced by the more powerful
  Cs\_primitive[unmanaged\_metadata] parameter (#275). To update, you need to
  replace `manage_target_role => false` by `unmanaged_metadata => ['targes-role']`
- The class parameter corosync::packages has been removed (was deprecated in
  0.8.0) (#282)

### Deprecation notes

We will remove support for Puppet <= 3.6.0 in two major releases of this module
(4.0.0).

## 2016-06-16 - Release 1.2.1
### Summary
- Workaround upstream Puppet bug regarding PuppetX ruby namespace (#278 #284
  SERVER-973)

## 2016-06-14 - Release 1.2.0
### Summary
- Deprecate Cs\_primitive[manage\_target\_role] in favour of
  Cs\_primitive[unmanaged_metadata]

## 2016-06-16 - Release 1.1.1
### Summary
- Workaround upstream Puppet bug regarding PuppetX ruby namespace (#278 #284
  SERVER-973)

## 2016-06-13 - Release 1.1.0
### Summary
- Move helpers functions to PuppetX ruby namespace (#259)
- Cs\_commit used with cs\_shadow are now idempotent (#263)
- Cs\_primitive: Fix metadata removal when the metadata parameter is empty (#264)
- Cs\_primitive: Add a manage\_target\_role parameter (#265)
- Inner changes to the crm providers to better manage the
  crm commands (#217 #268 #269 #270 #271 #272 #273)
- Adoption of Vox Pupuli code of conduct (coc) for further contributions (#267)

## 2016-05-24 - Release 1.0.2
### Summary
- Puppet 4.5.0 support (#258)
- Modulesync update

## 2016-05-23 - Release 1.0.1
### Summary
- Minor fix to the release scripts

## 2016-05-23 - Release 1.0.0
### Summary
- Ubuntu 14.04 support (#178)
- pcs provider: improved support for cs\_shadow, cs\_commit(#197 #196 #209)
- cs\_property now takes an optional `replace` parameter that do not update
  previously created parameters. Useful to let users change the settings at
  runtime without stopping puppet (e.g for maintenance mode) (#203)
- cs\_location now supports a resource\_discovery parameter that matches
  pacemaker resource-discovery location property
- cs\_property will now wait for the cluster to be ready (#170)
- Log the crm and pcs commands output (crmsh: #177, pcs: #219)
- cs\_property will only take care of cib-bootstrap-options cluster property set
  (crm: #174 pcs: #224)
- crm provider: Fix cs\_colocation for resources with a role (#175)
- cs\_commit now autorequires cs\_groups (#183)
- support for more corosync configuration parameters (#184 #192 #194)
- pcs provider: speed enhancements (#187)
- pcs provider: cs_order: implement the kind and symmetrical parameters (#188
  and #131
- pcs provider: cs_colocation: Add support for colocation sets (#190)
- add support for the pcsd service (#130)
- crm provider: Preserve resource order in cs_group (#133)
- corosync: support for multiple rings in unicast mode (#251)
- Bugfixes, improved tests, improved documentation



### Backward incompatible changes
- cs\_commit resources now only commit when refreshed (see README) (#209)
- pcs provider: cs\_location: the order of the primitives is now the chronological
  order: ['with-rsc', 'rsc']. This aligns pcs with the crmsh provider (#212)
- pcs_provider: cs\_colocation: the order of the primitives is now respected.
  Previously they were sorted by chronological order (#153).
- cs_primitive operations parameter with a role now need to define the role as
  a property, and if multiple operations have the same role you have to use an
  array (#236)
- cs\_order: the resources\_type parameter has been removed (#246)

## 2015-10-14 - Release 0.8.0
### Summary
- manage package and version for pcs
- Use Puppet::Type.newtype instead of Puppet.newtype
- Fix deprecation warning for SUIDManager.
- Fix acceptance tests for RHEL6 and Ubuntu 14.04
- Implement ensure => $version for pacemaker and corosync package
- Made pacemaker and corosync version configurable
  - Added variables to manage pacemaker or corosync package.
  - Added variables to manage pacemaker and corosync version.
  - Moved package parameters to init.pp. Required to accomodate the logic that allows new style $package\_{corosync,pacemaker} parameters, and the old-style $packages to co-exist in a safe manner.
  - Added deprecation warning for $packages parameter and fail() for mixed use of $packages and $package\_{corosync,pacemaker}.
  - Added spec tests for new package parameters.
- Added failure spec test for mixed use of $packages and $package\_\*.
- Made token\_retransmits\_before\_loss\_const a parameter to allow hearbeat tuning
- Move beaker to system-tests group
- Add spec for cs\_colocation
- Add basic beaker-rspec testing
- Colocation is allowed on _at least_ 2 primitives
- Bugfix,  crmsh cs\_location provider
- param mcastport is still used when using broadcast mode
- Fixed ordering of self.ready? tests
- Added caching on self.ready
- Ensure node IDs for votequorum are not "0"
- Add votequorum setting to corosync.conf
- Add cs\_clone provider and type (complete)
- Implement rsc\_defaults
- make token value configurable

## 2014-12-2 - Release 0.7.0
### Summary
This release refactors the main class to use `corosync::params` for defaults and no longer checks global variables for the parameters. It also includes strict variable support, a few other features, and a bugfix for EL platforms.

#### Backwards Incompatible Changes
Class `corosync` no longer uses global varaibles `$::port`, `$::threads`, `$::port`, `$::bind_address`, `$::unicast_addresses`, `$::multicast_address`, or `$::enable_secauth`. These should be passed as parameters to the `corosync` class instead.

#### Features
- Strict variable support
- Add support for spaces in `cs_primitive` parameters
- Add support for multiple operations with the same name
- Add some parameter validation

#### Bugfixes
- Removed `enable corosync` exec for EL platforms

## 2014-07-15 - Release 0.6.0
### Summary

This release adds support for the PCS provider.  It also updates metadata.json
so the module can be uninstalled and upgraded via the puppet module command.

#### Features
- Add support for PCS provider

## 2014-06-24 - Release 0.5.0
### Summary

This module has undergone two years of development, and pretty much every
aspect of it has changed in some regard.  I've tried to capture the key
changes below, but you should rely on the README to see how things work
now.

#### Features
- Added a new resource type cs_location.
- Make primitive utilization attributes managable.
- Added symmetrical parameter on cs_order (for ordering).
- Allow ordering of cs_groups.
- Allow to specify rrpmode and ttl.
- Allow to specifiy several rings.
- Permit broadcast.
- Allow more than two primitives per cs_colocation.
- Allow the authkey to be provided as a string.
- Add tests.
- Rework significant amounts of the provider code.

#### Bugfixes
- Delete an existing cib to start fresh
- Only change /etc/defaults for corosync startup on Debian platforms
- Fix templates for Puppet 3.2+.
- Don't complain if cs_primitive doesn't have a utilization parameter.
- Consider <instance_attributes/> within primitive operations.
- Changed osfamily check to include other operating systems.
- Updated node to node_name in cs_location function as 'node' is a reserved
name, this replacement allows cs_location to work correctly.

## 2012-10-14 - Release 0.1.0
- Added robustness for general corosync management (read the merges)
- Added `cs_group` type
- Added some testing
- Generally tried to get on top of this thing.


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*