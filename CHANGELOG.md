# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v6.0.0](https://github.com/voxpupuli/puppet-corosync/tree/v6.0.0) (2017-10-25)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v5.0.0...v6.0.0)

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

## [v5.0.0](https://github.com/voxpupuli/puppet-corosync/tree/v5.0.0) (2016-09-16)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v5.0.0-beta2...v5.0.0)

**Breaking changes:**

- Improve cs\_clone [\#367](https://github.com/voxpupuli/puppet-corosync/pull/367) ([roidelapluie](https://github.com/roidelapluie))

**Implemented enhancements:**

- clone of a group isn't supported [\#176](https://github.com/voxpupuli/puppet-corosync/issues/176)
- Autorequire primitives and clone in cs\_location [\#359](https://github.com/voxpupuli/puppet-corosync/pull/359) ([roidelapluie](https://github.com/roidelapluie))

**Fixed bugs:**

- CentOS 7 Startup issue [\#181](https://github.com/voxpupuli/puppet-corosync/issues/181)

**Closed issues:**

- puppet Error defining cs\_primitive [\#308](https://github.com/voxpupuli/puppet-corosync/issues/308)
- Clone names can't be overridden [\#149](https://github.com/voxpupuli/puppet-corosync/issues/149)

**Merged pull requests:**

- Support clone of groups [\#371](https://github.com/voxpupuli/puppet-corosync/pull/371) ([roidelapluie](https://github.com/roidelapluie))
- Multiple improvements for cs\_clones [\#370](https://github.com/voxpupuli/puppet-corosync/pull/370) ([roidelapluie](https://github.com/roidelapluie))
- Reduce logs verbosity [\#369](https://github.com/voxpupuli/puppet-corosync/pull/369) ([roidelapluie](https://github.com/roidelapluie))
- Allow cs\_group 1-array primitives [\#368](https://github.com/voxpupuli/puppet-corosync/pull/368) ([roidelapluie](https://github.com/roidelapluie))
- Release 5.0.0-beta2 [\#366](https://github.com/voxpupuli/puppet-corosync/pull/366) ([roidelapluie](https://github.com/roidelapluie))

## [v5.0.0-beta2](https://github.com/voxpupuli/puppet-corosync/tree/v5.0.0-beta2) (2016-09-13)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/5.0.0-beta1...v5.0.0-beta2)

**Implemented enhancements:**

- Add managed By Puppet header [\#360](https://github.com/voxpupuli/puppet-corosync/pull/360) ([roidelapluie](https://github.com/roidelapluie))
- Clone requires its primitive [\#357](https://github.com/voxpupuli/puppet-corosync/pull/357) ([roidelapluie](https://github.com/roidelapluie))
- Adding rule property to crm location [\#356](https://github.com/voxpupuli/puppet-corosync/pull/356) ([roidelapluie](https://github.com/roidelapluie))

**Fixed bugs:**

- Fix the two-node options with multiple nic [\#358](https://github.com/voxpupuli/puppet-corosync/pull/358) ([roidelapluie](https://github.com/roidelapluie))

**Closed issues:**

- cleanup everything between acceptance tests [\#363](https://github.com/voxpupuli/puppet-corosync/issues/363)
- add guards for empty autorequires [\#362](https://github.com/voxpupuli/puppet-corosync/issues/362)
- test autorequires [\#361](https://github.com/voxpupuli/puppet-corosync/issues/361)
- Disallow squash [\#352](https://github.com/voxpupuli/puppet-corosync/issues/352)

**Merged pull requests:**

- Improve \(and test!\) cs\_clone autorequires [\#365](https://github.com/voxpupuli/puppet-corosync/pull/365) ([roidelapluie](https://github.com/roidelapluie))
- Cleanup resources [\#364](https://github.com/voxpupuli/puppet-corosync/pull/364) ([roidelapluie](https://github.com/roidelapluie))
- Polish Readme [\#354](https://github.com/voxpupuli/puppet-corosync/pull/354) ([roidelapluie](https://github.com/roidelapluie))
- Release 5.0.0-beta1 [\#353](https://github.com/voxpupuli/puppet-corosync/pull/353) ([roidelapluie](https://github.com/roidelapluie))
- Improve 2 nodes test [\#351](https://github.com/voxpupuli/puppet-corosync/pull/351) ([roidelapluie](https://github.com/roidelapluie))
- Fix two\_nodes behaviour with expected\_votes = 2 [\#346](https://github.com/voxpupuli/puppet-corosync/pull/346) ([roidelapluie](https://github.com/roidelapluie))

## [5.0.0-beta1](https://github.com/voxpupuli/puppet-corosync/tree/5.0.0-beta1) (2016-09-05)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v4.0.1...5.0.0-beta1)

**Breaking changes:**

- Major cleanup of corosync.conf.erb [\#345](https://github.com/voxpupuli/puppet-corosync/pull/345) ([roidelapluie](https://github.com/roidelapluie))

**Merged pull requests:**

- Changelog for \#347 [\#349](https://github.com/voxpupuli/puppet-corosync/pull/349) ([roidelapluie](https://github.com/roidelapluie))
- Add the nodelist as often as possible [\#347](https://github.com/voxpupuli/puppet-corosync/pull/347) ([roidelapluie](https://github.com/roidelapluie))
- Merge 4.0.1 in master and update author in metadata.json [\#344](https://github.com/voxpupuli/puppet-corosync/pull/344) ([roidelapluie](https://github.com/roidelapluie))
- Release 4.0.1 [\#342](https://github.com/voxpupuli/puppet-corosync/pull/342) ([roidelapluie](https://github.com/roidelapluie))
- Fix disabling of authkey [\#341](https://github.com/voxpupuli/puppet-corosync/pull/341) ([roidelapluie](https://github.com/roidelapluie))

## [v4.0.1](https://github.com/voxpupuli/puppet-corosync/tree/v4.0.1) (2016-09-02)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v4.0.0...v4.0.1)

**Breaking changes:**

- Move min Puppet version to 3.8 [\#334](https://github.com/voxpupuli/puppet-corosync/pull/334) ([roidelapluie](https://github.com/roidelapluie))

**Implemented enhancements:**

- Add support for multiple rings in node list [\#262](https://github.com/voxpupuli/puppet-corosync/issues/262)

**Merged pull requests:**

- Changelog and Roadmap update [\#338](https://github.com/voxpupuli/puppet-corosync/pull/338) ([roidelapluie](https://github.com/roidelapluie))
- STRICT\_VARIABLES is on by default in Puppet 4 [\#337](https://github.com/voxpupuli/puppet-corosync/pull/337) ([roidelapluie](https://github.com/roidelapluie))
- Allow multiple rings in nodelist [\#336](https://github.com/voxpupuli/puppet-corosync/pull/336) ([roidelapluie](https://github.com/roidelapluie))
- Add --trace and --debug to puppet apply in acceptance tests [\#335](https://github.com/voxpupuli/puppet-corosync/pull/335) ([roidelapluie](https://github.com/roidelapluie))
- fix examples in README [\#333](https://github.com/voxpupuli/puppet-corosync/pull/333) ([roidelapluie](https://github.com/roidelapluie))
- Readme polishing [\#332](https://github.com/voxpupuli/puppet-corosync/pull/332) ([roidelapluie](https://github.com/roidelapluie))
- Abstract loading of the pcs cib [\#331](https://github.com/voxpupuli/puppet-corosync/pull/331) ([roidelapluie](https://github.com/roidelapluie))
- Simplify pcs command expectation [\#328](https://github.com/voxpupuli/puppet-corosync/pull/328) ([roidelapluie](https://github.com/roidelapluie))
- Release 4.0.0 [\#325](https://github.com/voxpupuli/puppet-corosync/pull/325) ([roidelapluie](https://github.com/roidelapluie))
- Reproduce \#308 [\#309](https://github.com/voxpupuli/puppet-corosync/pull/309) ([roidelapluie](https://github.com/roidelapluie))

## [v4.0.0](https://github.com/voxpupuli/puppet-corosync/tree/v4.0.0) (2016-08-30)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v3.0.0...v4.0.0)

**Fixed bugs:**

- Wrong syntax in pcs command call [\#199](https://github.com/voxpupuli/puppet-corosync/issues/199)

**Closed issues:**

- PCCI ubuntu 12.04 + centos 6 [\#213](https://github.com/voxpupuli/puppet-corosync/issues/213)
- Colocation constraints with pcs provider are broken, incorrectly assume bidirectionality, swap order of primitives around [\#150](https://github.com/voxpupuli/puppet-corosync/issues/150)

**Merged pull requests:**

- New badges to celebrate the "Approved" tag [\#324](https://github.com/voxpupuli/puppet-corosync/pull/324) ([roidelapluie](https://github.com/roidelapluie))
- allow corosync configuration with cluster\_name only [\#323](https://github.com/voxpupuli/puppet-corosync/pull/323) ([roidelapluie](https://github.com/roidelapluie))
- Update changelog [\#321](https://github.com/voxpupuli/puppet-corosync/pull/321) ([roidelapluie](https://github.com/roidelapluie))
- Travis Workaround [\#320](https://github.com/voxpupuli/puppet-corosync/pull/320) ([roidelapluie](https://github.com/roidelapluie))
- Set minimum Puppet version to 3.6.0 [\#319](https://github.com/voxpupuli/puppet-corosync/pull/319) ([roidelapluie](https://github.com/roidelapluie))
- Test corosync config where appropriate [\#294](https://github.com/voxpupuli/puppet-corosync/pull/294) ([roidelapluie](https://github.com/roidelapluie))

## [v3.0.0](https://github.com/voxpupuli/puppet-corosync/tree/v3.0.0) (2016-08-18)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v2.0.1...v3.0.0)

**Closed issues:**

- default token value of 3000 is not a supported config [\#300](https://github.com/voxpupuli/puppet-corosync/issues/300)

**Merged pull requests:**

- Update Changelog for 3.0.0 \[ci skip\] [\#317](https://github.com/voxpupuli/puppet-corosync/pull/317) ([roidelapluie](https://github.com/roidelapluie))
- Do not set two\_nodes on three-node cluster with expected\_votes = 2 [\#316](https://github.com/voxpupuli/puppet-corosync/pull/316) ([roidelapluie](https://github.com/roidelapluie))
- Remove Centos 6 tests [\#315](https://github.com/voxpupuli/puppet-corosync/pull/315) ([roidelapluie](https://github.com/roidelapluie))
- Improve corosync readiness detection [\#314](https://github.com/voxpupuli/puppet-corosync/pull/314) ([roidelapluie](https://github.com/roidelapluie))
- Rename .pcci.yaml to .pcci.yml [\#307](https://github.com/voxpupuli/puppet-corosync/pull/307) ([roidelapluie](https://github.com/roidelapluie))
- "Add .pcci.yaml" [\#304](https://github.com/voxpupuli/puppet-corosync/pull/304) ([nibalizer](https://github.com/nibalizer))
- travis: build the module [\#303](https://github.com/voxpupuli/puppet-corosync/pull/303) ([roidelapluie](https://github.com/roidelapluie))
- Release 2.0.1 [\#302](https://github.com/voxpupuli/puppet-corosync/pull/302) ([roidelapluie](https://github.com/roidelapluie))

## [v2.0.1](https://github.com/voxpupuli/puppet-corosync/tree/v2.0.1) (2016-06-28)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v2.0.0...v2.0.1)

**Merged pull requests:**

- Update changelog [\#298](https://github.com/voxpupuli/puppet-corosync/pull/298) ([roidelapluie](https://github.com/roidelapluie))
- Release 2.0.0 [\#297](https://github.com/voxpupuli/puppet-corosync/pull/297) ([roidelapluie](https://github.com/roidelapluie))
- Ubuntu 16.04 support [\#288](https://github.com/voxpupuli/puppet-corosync/pull/288) ([roidelapluie](https://github.com/roidelapluie))

## [v2.0.0](https://github.com/voxpupuli/puppet-corosync/tree/v2.0.0) (2016-06-28)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v1.2.1...v2.0.0)

**Fixed bugs:**

- Could not autoload puppet/type/cs\_property [\#278](https://github.com/voxpupuli/puppet-corosync/issues/278)

**Closed issues:**

- Type cs\_rsc\_defaults is missing the cib parameter  [\#295](https://github.com/voxpupuli/puppet-corosync/issues/295)
- Confused by the Versioning on this Module [\#290](https://github.com/voxpupuli/puppet-corosync/issues/290)
- location rules definition missing [\#289](https://github.com/voxpupuli/puppet-corosync/issues/289)

**Merged pull requests:**

- Fix \#295 - Add a CIb parameter to cs\_rsc\_defaults [\#296](https://github.com/voxpupuli/puppet-corosync/pull/296) ([roidelapluie](https://github.com/roidelapluie))
- don't explicitly include puppet-lint [\#292](https://github.com/voxpupuli/puppet-corosync/pull/292) ([bastelfreak](https://github.com/bastelfreak))
- Improve cs\_order acceptance spec tests [\#287](https://github.com/voxpupuli/puppet-corosync/pull/287) ([roidelapluie](https://github.com/roidelapluie))
- Add Puppet Compatibility to metadata.json [\#286](https://github.com/voxpupuli/puppet-corosync/pull/286) ([roidelapluie](https://github.com/roidelapluie))
- Merge 1.2 [\#285](https://github.com/voxpupuli/puppet-corosync/pull/285) ([roidelapluie](https://github.com/roidelapluie))
- Update changelog [\#283](https://github.com/voxpupuli/puppet-corosync/pull/283) ([roidelapluie](https://github.com/roidelapluie))
- Support Debian-8 [\#282](https://github.com/voxpupuli/puppet-corosync/pull/282) ([roidelapluie](https://github.com/roidelapluie))
- Investigate \#279 [\#281](https://github.com/voxpupuli/puppet-corosync/pull/281) ([roidelapluie](https://github.com/roidelapluie))

## [v1.2.1](https://github.com/voxpupuli/puppet-corosync/tree/v1.2.1) (2016-06-16)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v1.1.1...v1.2.1)

**Merged pull requests:**

- Workaround for SERVER-973 [\#284](https://github.com/voxpupuli/puppet-corosync/pull/284) ([roidelapluie](https://github.com/roidelapluie))

## [v1.1.1](https://github.com/voxpupuli/puppet-corosync/tree/v1.1.1) (2016-06-16)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v1.2.0...v1.1.1)

**Merged pull requests:**

- Deprecate cs\_primitive.rb\[manage\_target\_role\] [\#277](https://github.com/voxpupuli/puppet-corosync/pull/277) ([roidelapluie](https://github.com/roidelapluie))
- Docker Beaker [\#276](https://github.com/voxpupuli/puppet-corosync/pull/276) ([roidelapluie](https://github.com/roidelapluie))
- Add unmanaged\_metadata to ignore metadata in Puppet [\#275](https://github.com/voxpupuli/puppet-corosync/pull/275) ([roidelapluie](https://github.com/roidelapluie))

## [v1.2.0](https://github.com/voxpupuli/puppet-corosync/tree/v1.2.0) (2016-06-14)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v1.1.0...v1.2.0)

## [v1.1.0](https://github.com/voxpupuli/puppet-corosync/tree/v1.1.0) (2016-06-13)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v1.0.2...v1.1.0)

**Closed issues:**

- move helpers to lib/puppet\_x [\#249](https://github.com/voxpupuli/puppet-corosync/issues/249)
- use run\_command\_in\_cib everywhere in the crmsh provider [\#217](https://github.com/voxpupuli/puppet-corosync/issues/217)

**Merged pull requests:**

- Release 1.1.0 [\#274](https://github.com/voxpupuli/puppet-corosync/pull/274) ([roidelapluie](https://github.com/roidelapluie))
- cs\_clone/crm: use run\_command\_in\_cib [\#273](https://github.com/voxpupuli/puppet-corosync/pull/273) ([roidelapluie](https://github.com/roidelapluie))
- cs\_colocation/crm: use run\_command\_in\_cib [\#272](https://github.com/voxpupuli/puppet-corosync/pull/272) ([roidelapluie](https://github.com/roidelapluie))
- cs\_primitive/crm: use run\_command\_in\_cib and run in shadow CIB [\#271](https://github.com/voxpupuli/puppet-corosync/pull/271) ([roidelapluie](https://github.com/roidelapluie))
- cs\_group/crm: use run\_command\_in\_cib [\#270](https://github.com/voxpupuli/puppet-corosync/pull/270) ([roidelapluie](https://github.com/roidelapluie))
- cs\_rsc\_defaults/crm: use run\_command\_in\_cib and run in shadow CIB [\#269](https://github.com/voxpupuli/puppet-corosync/pull/269) ([roidelapluie](https://github.com/roidelapluie))
- cs\_property/crm: use run\_command\_in\_cib and run in shadow CIB [\#268](https://github.com/voxpupuli/puppet-corosync/pull/268) ([roidelapluie](https://github.com/roidelapluie))
- Update Changelog [\#266](https://github.com/voxpupuli/puppet-corosync/pull/266) ([roidelapluie](https://github.com/roidelapluie))
- Add manage\_target\_role parameter [\#265](https://github.com/voxpupuli/puppet-corosync/pull/265) ([roidelapluie](https://github.com/roidelapluie))
- cs\_primitive: Fix metadata management with the pcs provider [\#264](https://github.com/voxpupuli/puppet-corosync/pull/264) ([roidelapluie](https://github.com/roidelapluie))
- Fix idempotency of cs\_commit [\#263](https://github.com/voxpupuli/puppet-corosync/pull/263) ([roidelapluie](https://github.com/roidelapluie))
- Update Changelog [\#261](https://github.com/voxpupuli/puppet-corosync/pull/261) ([roidelapluie](https://github.com/roidelapluie))
- Move helper libs to PuppetX [\#259](https://github.com/voxpupuli/puppet-corosync/pull/259) ([roidelapluie](https://github.com/roidelapluie))

## [v1.0.2](https://github.com/voxpupuli/puppet-corosync/tree/v1.0.2) (2016-05-24)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v1.0.1...v1.0.2)

**Merged pull requests:**

- Ensure autorequires is empty if there is no cib parameters [\#258](https://github.com/voxpupuli/puppet-corosync/pull/258) ([roidelapluie](https://github.com/roidelapluie))
- fix travis and modulesync [\#257](https://github.com/voxpupuli/puppet-corosync/pull/257) ([bastelfreak](https://github.com/bastelfreak))

## [v1.0.1](https://github.com/voxpupuli/puppet-corosync/tree/v1.0.1) (2016-05-23)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/v1.0.0...v1.0.1)

## [v1.0.0](https://github.com/voxpupuli/puppet-corosync/tree/v1.0.0) (2016-05-23)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/1.0.0-beta1...v1.0.0)

**Implemented enhancements:**

- Support Ruby 2.2.x [\#204](https://github.com/voxpupuli/puppet-corosync/issues/204)

**Closed issues:**

- `cs\_group` resource cannot handle `ensure =\> absent` [\#18](https://github.com/voxpupuli/puppet-corosync/issues/18)
- `cs\_primitive` resources without a `parameters` attribute are not realized. [\#17](https://github.com/voxpupuli/puppet-corosync/issues/17)
- `crm configure load update` returns 0 on error [\#13](https://github.com/voxpupuli/puppet-corosync/issues/13)

**Merged pull requests:**

- Fix to work with Ruby 2.3 \(in Ubuntu 16.04\). [\#254](https://github.com/voxpupuli/puppet-corosync/pull/254) ([tdb](https://github.com/tdb))
- Update modulesync\(0.5.1\) [\#253](https://github.com/voxpupuli/puppet-corosync/pull/253) ([roidelapluie](https://github.com/roidelapluie))

## [1.0.0-beta1](https://github.com/voxpupuli/puppet-corosync/tree/1.0.0-beta1) (2016-04-14)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/0.8.0...1.0.0-beta1)

**Breaking changes:**

- Fix Centos Acceptance test [\#212](https://github.com/voxpupuli/puppet-corosync/pull/212) ([roidelapluie](https://github.com/roidelapluie))
- Fix and improve a lot cs\_commit, cs\_shadow support for pcs [\#209](https://github.com/voxpupuli/puppet-corosync/pull/209) ([roidelapluie](https://github.com/roidelapluie))
- Enable pacemaker by default on Centos7 [\#201](https://github.com/voxpupuli/puppet-corosync/pull/201) ([roidelapluie](https://github.com/roidelapluie))

**Closed issues:**

- Warning after latest changes merged [\#248](https://github.com/voxpupuli/puppet-corosync/issues/248)
- Support for multiples rings [\#244](https://github.com/voxpupuli/puppet-corosync/issues/244)
- issue with cs\_order and roles [\#239](https://github.com/voxpupuli/puppet-corosync/issues/239)
- Unable to find operation matching: monitor:Master [\#234](https://github.com/voxpupuli/puppet-corosync/issues/234)
- missing autedependency [\#232](https://github.com/voxpupuli/puppet-corosync/issues/232)
- Cs\_colocation Could not evaluate: undefined method `include?' for nil:NilClass [\#231](https://github.com/voxpupuli/puppet-corosync/issues/231)
- Undefined method 'first' [\#229](https://github.com/voxpupuli/puppet-corosync/issues/229)
- port \#174 to the pcs provider [\#222](https://github.com/voxpupuli/puppet-corosync/issues/222)
- Post-\#209: Add cs\_property {replace=\> no} in the changelog [\#215](https://github.com/voxpupuli/puppet-corosync/issues/215)
- Post-\#209: check why there is an exception for RedHat in acceptance tests [\#214](https://github.com/voxpupuli/puppet-corosync/issues/214)
- Steps to do before a -beta1 [\#206](https://github.com/voxpupuli/puppet-corosync/issues/206)
- When adding/removing cluster nodes, use configurable node IDs in the nodelist config [\#193](https://github.com/voxpupuli/puppet-corosync/issues/193)
- cs\_colocation's self.instances is huge, and should be split [\#179](https://github.com/voxpupuli/puppet-corosync/issues/179)
- Flush cs properties in one go [\#173](https://github.com/voxpupuli/puppet-corosync/issues/173)
- Github project URL still points to the PL forge project [\#167](https://github.com/voxpupuli/puppet-corosync/issues/167)
- Beaker tests results are irrelevant [\#163](https://github.com/voxpupuli/puppet-corosync/issues/163)
- pcs: constraints, groups do not delay creation of primitives [\#157](https://github.com/voxpupuli/puppet-corosync/issues/157)
- Test basic compatibility with Puppet 3.8.x \(on RHEL7\) [\#146](https://github.com/voxpupuli/puppet-corosync/issues/146)
- Incorrect/incomplete autorequire in cs\_primitive type [\#145](https://github.com/voxpupuli/puppet-corosync/issues/145)
- 0.7.0 release broken; corosync.conf template creates configuration file that makes it impossible for corosync daemon to start [\#144](https://github.com/voxpupuli/puppet-corosync/issues/144)
- Incomplete support for Corosync 2.x [\#143](https://github.com/voxpupuli/puppet-corosync/issues/143)
- trying to sed file that does not exist [\#39](https://github.com/voxpupuli/puppet-corosync/issues/39)
- RHEL 6.4: crm replaced by pcs [\#36](https://github.com/voxpupuli/puppet-corosync/issues/36)
- `cs\_shadow` and `cs\_commit` should not create changes every run. [\#15](https://github.com/voxpupuli/puppet-corosync/issues/15)

**Merged pull requests:**

- Support multiple rings in a unicast setup [\#251](https://github.com/voxpupuli/puppet-corosync/pull/251) ([roidelapluie](https://github.com/roidelapluie))
- Implements install\_options for packages [\#250](https://github.com/voxpupuli/puppet-corosync/pull/250) ([Slm0n87](https://github.com/Slm0n87))
- Fix persistent node IDs for all conf cases [\#247](https://github.com/voxpupuli/puppet-corosync/pull/247) ([bogdando](https://github.com/bogdando))
- Simplify cs\_order and cs\_colocation autorequires [\#246](https://github.com/voxpupuli/puppet-corosync/pull/246) ([roidelapluie](https://github.com/roidelapluie))
- Improve acceptance test and autorequire pacemaker [\#245](https://github.com/voxpupuli/puppet-corosync/pull/245) ([roidelapluie](https://github.com/roidelapluie))
- Add operatingsystem\_support to metadata.json [\#243](https://github.com/voxpupuli/puppet-corosync/pull/243) ([roidelapluie](https://github.com/roidelapluie))
- Fix cs\_order acceptance tests [\#242](https://github.com/voxpupuli/puppet-corosync/pull/242) ([roidelapluie](https://github.com/roidelapluie))
- Ensure that cs\_order is indempotent [\#241](https://github.com/voxpupuli/puppet-corosync/pull/241) ([roidelapluie](https://github.com/roidelapluie))
- cs\_commit: Improve the way we deal with autorequirements [\#240](https://github.com/voxpupuli/puppet-corosync/pull/240) ([roidelapluie](https://github.com/roidelapluie))
- Unpromote master resources in shadow CIB [\#238](https://github.com/voxpupuli/puppet-corosync/pull/238) ([roidelapluie](https://github.com/roidelapluie))
- Ensure backwards compatibility for cs\_primitive operations and improve change message [\#237](https://github.com/voxpupuli/puppet-corosync/pull/237) ([roidelapluie](https://github.com/roidelapluie))
-  Unable to find operation matching: monitor:Master \#234 [\#236](https://github.com/voxpupuli/puppet-corosync/pull/236) ([roidelapluie](https://github.com/roidelapluie))
- Add Dependency for cs\_clone in cs\_order [\#235](https://github.com/voxpupuli/puppet-corosync/pull/235) ([roidelapluie](https://github.com/roidelapluie))
- Add missing mk\_resource\_methods to cs\_order [\#233](https://github.com/voxpupuli/puppet-corosync/pull/233) ([roidelapluie](https://github.com/roidelapluie))
- Pin rake to avoid rubocop/rake 11 incompatibility [\#230](https://github.com/voxpupuli/puppet-corosync/pull/230) ([roidelapluie](https://github.com/roidelapluie))
- Handle logfile parameter in corosync configuration [\#228](https://github.com/voxpupuli/puppet-corosync/pull/228) ([roidelapluie](https://github.com/roidelapluie))
- pcs provider: Remove Lint/UselessAssignment hacks [\#227](https://github.com/voxpupuli/puppet-corosync/pull/227) ([roidelapluie](https://github.com/roidelapluie))
- Remove ENV\['CIB\_shadow'\] where not needed [\#226](https://github.com/voxpupuli/puppet-corosync/pull/226) ([roidelapluie](https://github.com/roidelapluie))
- Normalize autorequire cs\_shadow [\#225](https://github.com/voxpupuli/puppet-corosync/pull/225) ([roidelapluie](https://github.com/roidelapluie))
- pcs provider: only parse cib-bootstrap-options property set [\#224](https://github.com/voxpupuli/puppet-corosync/pull/224) ([roidelapluie](https://github.com/roidelapluie))
- Update README [\#223](https://github.com/voxpupuli/puppet-corosync/pull/223) ([roidelapluie](https://github.com/roidelapluie))
- Refactor cs\_primitive tests [\#220](https://github.com/voxpupuli/puppet-corosync/pull/220) ([roidelapluie](https://github.com/roidelapluie))
- Add a resource\_discovery property to cs\_location [\#219](https://github.com/voxpupuli/puppet-corosync/pull/219) ([roidelapluie](https://github.com/roidelapluie))
- Improve acceptance tests and improve commits and shadows [\#218](https://github.com/voxpupuli/puppet-corosync/pull/218) ([roidelapluie](https://github.com/roidelapluie))
- Release 1.0.0-beta [\#216](https://github.com/voxpupuli/puppet-corosync/pull/216) ([roidelapluie](https://github.com/roidelapluie))
- Fix race conditions found during cluster bootstrap [\#208](https://github.com/voxpupuli/puppet-corosync/pull/208) ([roidelapluie](https://github.com/roidelapluie))
- Move self.nvpairs\_to\_hash to provider/pacemaker.rb [\#207](https://github.com/voxpupuli/puppet-corosync/pull/207) ([roidelapluie](https://github.com/roidelapluie))
- Document set\_votequorum defaults correctly [\#205](https://github.com/voxpupuli/puppet-corosync/pull/205) ([roman-mueller](https://github.com/roman-mueller))
- Add a replace parameter to cs\_property [\#203](https://github.com/voxpupuli/puppet-corosync/pull/203) ([roidelapluie](https://github.com/roidelapluie))
- Don't use sed on debian [\#202](https://github.com/voxpupuli/puppet-corosync/pull/202) ([jyaworski](https://github.com/jyaworski))
- Fix function call syntax in cs\_colocation PCS provider [\#198](https://github.com/voxpupuli/puppet-corosync/pull/198) ([oranenj](https://github.com/oranenj))
- crm\_shadow --commit/--delete need --force to execute [\#197](https://github.com/voxpupuli/puppet-corosync/pull/197) ([GiooDev](https://github.com/GiooDev))
- Fix missing CIB\_shadow on cs\_colocation and cs\_location. [\#196](https://github.com/voxpupuli/puppet-corosync/pull/196) ([GiooDev](https://github.com/GiooDev))
- Modulesync [\#195](https://github.com/voxpupuli/puppet-corosync/pull/195) ([juniorsysadmin](https://github.com/juniorsysadmin))
- Add persistent node IDs as a config option [\#194](https://github.com/voxpupuli/puppet-corosync/pull/194) ([bogdando](https://github.com/bogdando))
- Improve logging configuration [\#192](https://github.com/voxpupuli/puppet-corosync/pull/192) ([bogdando](https://github.com/bogdando))
- Add a getter for cs\_order.symmetrical [\#191](https://github.com/voxpupuli/puppet-corosync/pull/191) ([roidelapluie](https://github.com/roidelapluie))
- Add support for collocation sets [\#190](https://github.com/voxpupuli/puppet-corosync/pull/190) ([roidelapluie](https://github.com/roidelapluie))
- Compare versions using Puppet::Util::Package.versioncmp [\#189](https://github.com/voxpupuli/puppet-corosync/pull/189) ([roidelapluie](https://github.com/roidelapluie))
- Add kind parameter to cs\_order. [\#188](https://github.com/voxpupuli/puppet-corosync/pull/188) ([GiooDev](https://github.com/GiooDev))
- Improved 'pcs property show dc-version' to speed up things. [\#187](https://github.com/voxpupuli/puppet-corosync/pull/187) ([GiooDev](https://github.com/GiooDev))
- update README.md, fix example with operations with the same names [\#186](https://github.com/voxpupuli/puppet-corosync/pull/186) ([pulecp](https://github.com/pulecp))
- Add parameters for corosync.conf file [\#184](https://github.com/voxpupuli/puppet-corosync/pull/184) ([GiooDev](https://github.com/GiooDev))
- Missing autorequire for cs\_group on cs\_commit type. [\#183](https://github.com/voxpupuli/puppet-corosync/pull/183) ([GiooDev](https://github.com/GiooDev))
- Add support for Ubuntu 14.04 [\#178](https://github.com/voxpupuli/puppet-corosync/pull/178) ([tdb](https://github.com/tdb))
- Log crm updates [\#177](https://github.com/voxpupuli/puppet-corosync/pull/177) ([tdb](https://github.com/tdb))
- fixes cs\_colocation bug for resources with a role [\#175](https://github.com/voxpupuli/puppet-corosync/pull/175) ([rasschaert](https://github.com/rasschaert))
- only parse cluster\_property\_set with id cib-bootstrap-options [\#174](https://github.com/voxpupuli/puppet-corosync/pull/174) ([kraeuschen](https://github.com/kraeuschen))
- Fix Acceptance test [\#171](https://github.com/voxpupuli/puppet-corosync/pull/171) ([roidelapluie](https://github.com/roidelapluie))
- Do block until ready for cs\_property flush [\#170](https://github.com/voxpupuli/puppet-corosync/pull/170) ([bogdando](https://github.com/bogdando))
- Fix acceptance tests [\#169](https://github.com/voxpupuli/puppet-corosync/pull/169) ([roidelapluie](https://github.com/roidelapluie))
- metadata.json: Use SPDX standardized short identifier for license [\#168](https://github.com/voxpupuli/puppet-corosync/pull/168) ([roidelapluie](https://github.com/roidelapluie))
- Release 0.8.0 [\#165](https://github.com/voxpupuli/puppet-corosync/pull/165) ([mkrakowitzer](https://github.com/mkrakowitzer))
- Stop ignoring order of primitives in colocation constraints [\#153](https://github.com/voxpupuli/puppet-corosync/pull/153) ([fghaas](https://github.com/fghaas))
- Preserve resource order in cs\_group crm provider [\#133](https://github.com/voxpupuli/puppet-corosync/pull/133) ([arachnist](https://github.com/arachnist))
- Added symmetrical parameter on cs\_order for pcs provider [\#131](https://github.com/voxpupuli/puppet-corosync/pull/131) ([roidelapluie](https://github.com/roidelapluie))
- Managing pcs service on RHEL [\#130](https://github.com/voxpupuli/puppet-corosync/pull/130) ([GiooDev](https://github.com/GiooDev))
- Adding cluster\_name in corosync.conf [\#129](https://github.com/voxpupuli/puppet-corosync/pull/129) ([GiooDev](https://github.com/GiooDev))

## [0.8.0](https://github.com/voxpupuli/puppet-corosync/tree/0.8.0) (2015-10-14)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/0.7.0...0.8.0)

**Merged pull requests:**

- manage package and version for pcs [\#164](https://github.com/voxpupuli/puppet-corosync/pull/164) ([pulecp](https://github.com/pulecp))
- Stop trolling in README :\) [\#160](https://github.com/voxpupuli/puppet-corosync/pull/160) ([roidelapluie](https://github.com/roidelapluie))
- Use Puppet::Type.newtype instead of Puppet.newtype [\#159](https://github.com/voxpupuli/puppet-corosync/pull/159) ([roidelapluie](https://github.com/roidelapluie))
- Fix acceptance tests for RHEL6 and Ubuntu 14.04 [\#158](https://github.com/voxpupuli/puppet-corosync/pull/158) ([cmurphy](https://github.com/cmurphy))
- Cs colocation crm spec [\#155](https://github.com/voxpupuli/puppet-corosync/pull/155) ([mkrakowitzer](https://github.com/mkrakowitzer))
- Implement ensure =\> $version for pacemaker and corosync package [\#141](https://github.com/voxpupuli/puppet-corosync/pull/141) ([stefanandres](https://github.com/stefanandres))
- Set up PC dotfiles, modify readme [\#140](https://github.com/voxpupuli/puppet-corosync/pull/140) ([nibalizer](https://github.com/nibalizer))
- Fix deprecation warning for SUIDManager. [\#138](https://github.com/voxpupuli/puppet-corosync/pull/138) ([tdb](https://github.com/tdb))
- Update metadata.json [\#137](https://github.com/voxpupuli/puppet-corosync/pull/137) ([nibalizer](https://github.com/nibalizer))
- Pin rspec to 3.1.x [\#125](https://github.com/voxpupuli/puppet-corosync/pull/125) ([cmurphy](https://github.com/cmurphy))
- Move beaker to system-tests group [\#123](https://github.com/voxpupuli/puppet-corosync/pull/123) ([cmurphy](https://github.com/cmurphy))
- Rebase \#81 [\#120](https://github.com/voxpupuli/puppet-corosync/pull/120) ([cmurphy](https://github.com/cmurphy))
- Add initial beaker-rspec tests [\#119](https://github.com/voxpupuli/puppet-corosync/pull/119) ([cmurphy](https://github.com/cmurphy))
- Rebase \#34 [\#118](https://github.com/voxpupuli/puppet-corosync/pull/118) ([cmurphy](https://github.com/cmurphy))
- Added RedHat support [\#117](https://github.com/voxpupuli/puppet-corosync/pull/117) ([cmurphy](https://github.com/cmurphy))
- Rebase 77 [\#116](https://github.com/voxpupuli/puppet-corosync/pull/116) ([mkrakowitzer](https://github.com/mkrakowitzer))
- Fix \#100 - rebase and typo [\#115](https://github.com/voxpupuli/puppet-corosync/pull/115) ([cmurphy](https://github.com/cmurphy))
- Bugfix - crmsh cs\_location provider [\#114](https://github.com/voxpupuli/puppet-corosync/pull/114) ([mkrakowitzer](https://github.com/mkrakowitzer))
- param mcastport is still used when using broadcast mode. [\#113](https://github.com/voxpupuli/puppet-corosync/pull/113) ([mkrakowitzer](https://github.com/mkrakowitzer))
- Update rspec syntax for rspec-puppet 2.0.0 [\#110](https://github.com/voxpupuli/puppet-corosync/pull/110) ([cmurphy](https://github.com/cmurphy))
- Rebase of \#51 [\#109](https://github.com/voxpupuli/puppet-corosync/pull/109) ([cmurphy](https://github.com/cmurphy))
- Ensure node IDs for votequorum are not "0" [\#108](https://github.com/voxpupuli/puppet-corosync/pull/108) ([madkiss](https://github.com/madkiss))
- Add votequorum setting to corosync.conf [\#106](https://github.com/voxpupuli/puppet-corosync/pull/106) ([paramite](https://github.com/paramite))
- Add cs\_clone provider and type \(complete\) [\#105](https://github.com/voxpupuli/puppet-corosync/pull/105) ([javierpena](https://github.com/javierpena))
- Fix syntax on crm cs\_primitive following PR\#90 [\#102](https://github.com/voxpupuli/puppet-corosync/pull/102) ([sathieu](https://github.com/sathieu))
- Update .travis.yml [\#101](https://github.com/voxpupuli/puppet-corosync/pull/101) ([cmurphy](https://github.com/cmurphy))
- Fixed regression in refactoring [\#99](https://github.com/voxpupuli/puppet-corosync/pull/99) ([elconas2](https://github.com/elconas2))
- Implement rsc\_defaults [\#91](https://github.com/voxpupuli/puppet-corosync/pull/91) ([sathieu](https://github.com/sathieu))
- make token value configurable [\#86](https://github.com/voxpupuli/puppet-corosync/pull/86) ([michakrause](https://github.com/michakrause))
- Fixes for pcs provider [\#77](https://github.com/voxpupuli/puppet-corosync/pull/77) ([jonhattan](https://github.com/jonhattan))

## [0.7.0](https://github.com/voxpupuli/puppet-corosync/tree/0.7.0) (2014-12-02)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/0.6.0...0.7.0)

**Merged pull requests:**

- 0.7.0 prep [\#97](https://github.com/voxpupuli/puppet-corosync/pull/97) ([underscorgan](https://github.com/underscorgan))
- MODULES-1547 - Strict variable support [\#96](https://github.com/voxpupuli/puppet-corosync/pull/96) ([underscorgan](https://github.com/underscorgan))
- Fix tests to pass under rspec 3 [\#93](https://github.com/voxpupuli/puppet-corosync/pull/93) ([cmurphy](https://github.com/cmurphy))
- Allow multiple operations with the same name [\#92](https://github.com/voxpupuli/puppet-corosync/pull/92) ([sathieu](https://github.com/sathieu))
- Allow spaces in cs\_primitive parameters [\#90](https://github.com/voxpupuli/puppet-corosync/pull/90) ([sathieu](https://github.com/sathieu))
- Fix a typo in README [\#89](https://github.com/voxpupuli/puppet-corosync/pull/89) ([roidelapluie](https://github.com/roidelapluie))
- Rename corosync to crmsh in cs\_location provider [\#88](https://github.com/voxpupuli/puppet-corosync/pull/88) ([holser](https://github.com/holser))
- Fix metadata links [\#82](https://github.com/voxpupuli/puppet-corosync/pull/82) ([ghoneycutt](https://github.com/ghoneycutt))
- Fixed 'enable corosync' on CentOS as there is no 'enable' on CentOS [\#79](https://github.com/voxpupuli/puppet-corosync/pull/79) ([elconas](https://github.com/elconas))

## [0.6.0](https://github.com/voxpupuli/puppet-corosync/tree/0.6.0) (2014-07-15)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/0.5.0...0.6.0)

**Merged pull requests:**

- Prepare 0.6.0 release. [\#74](https://github.com/voxpupuli/puppet-corosync/pull/74) ([apenney](https://github.com/apenney))
- Add support for PCS provider [\#64](https://github.com/voxpupuli/puppet-corosync/pull/64) ([roidelapluie](https://github.com/roidelapluie))

## [0.5.0](https://github.com/voxpupuli/puppet-corosync/tree/0.5.0) (2014-06-25)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/0.1.0...0.5.0)

**Closed issues:**

- Puppet error if utilization property of cs\_primitive not set. [\#52](https://github.com/voxpupuli/puppet-corosync/issues/52)
- utilization attributes of primitives can't be managed [\#40](https://github.com/voxpupuli/puppet-corosync/issues/40)
- Added clone, rsc\_options and location including rules [\#37](https://github.com/voxpupuli/puppet-corosync/issues/37)

**Merged pull requests:**

- Prepare 0.5.0 release. [\#71](https://github.com/voxpupuli/puppet-corosync/pull/71) ([apenney](https://github.com/apenney))
- Allow the authkey to be provided as a string [\#69](https://github.com/voxpupuli/puppet-corosync/pull/69) ([dmsimard](https://github.com/dmsimard))
- Modified node to node\_name in cs\_location function as 'node' is a reserved attribute [\#68](https://github.com/voxpupuli/puppet-corosync/pull/68) ([mikehelix](https://github.com/mikehelix))
- Syntax error in cs\_order type [\#67](https://github.com/voxpupuli/puppet-corosync/pull/67) ([mbakke](https://github.com/mbakke))
- \(maint\) remove unrequired distros from osfamily check. [\#66](https://github.com/voxpupuli/puppet-corosync/pull/66) ([apenney](https://github.com/apenney))
- Changed osfamily check to include other operating systems [\#65](https://github.com/voxpupuli/puppet-corosync/pull/65) ([Spechal](https://github.com/Spechal))
- Added cs\_property information to the read me [\#63](https://github.com/voxpupuli/puppet-corosync/pull/63) ([lmorfitt](https://github.com/lmorfitt))
- provide param to overwrite the list of packages which should be installed [\#62](https://github.com/voxpupuli/puppet-corosync/pull/62) ([bechtoldt](https://github.com/bechtoldt))
- removed multibyte chars from Modulefile [\#61](https://github.com/voxpupuli/puppet-corosync/pull/61) ([NITEMAN](https://github.com/NITEMAN))
- Consider \<instance\_attributes/\> within primitive operations [\#60](https://github.com/voxpupuli/puppet-corosync/pull/60) ([javiplx](https://github.com/javiplx))
- fix depreciation warning in latest puppet versions [\#59](https://github.com/voxpupuli/puppet-corosync/pull/59) ([roidelapluie](https://github.com/roidelapluie))
- added require=\>Package\['corosync'\] to authkey file [\#58](https://github.com/voxpupuli/puppet-corosync/pull/58) ([flypenguin](https://github.com/flypenguin))
- more than two primitives per cs\_colocation [\#56](https://github.com/voxpupuli/puppet-corosync/pull/56) ([blook](https://github.com/blook))
- Add Apache 2.0 license file. [\#55](https://github.com/voxpupuli/puppet-corosync/pull/55) ([apenney](https://github.com/apenney))
- Various enhancements [\#54](https://github.com/voxpupuli/puppet-corosync/pull/54) ([sathieu](https://github.com/sathieu))
- don't complain if cs\_primitive doesn't have a utilization parameter [\#53](https://github.com/voxpupuli/puppet-corosync/pull/53) ([bitglue](https://github.com/bitglue))
- Allow ordering of cs\_groups [\#50](https://github.com/voxpupuli/puppet-corosync/pull/50) ([kbon](https://github.com/kbon))
- Added symmetrical parameter on cs\_order [\#49](https://github.com/voxpupuli/puppet-corosync/pull/49) ([kbon](https://github.com/kbon))
- Template compatibility Puppet 3.2 [\#48](https://github.com/voxpupuli/puppet-corosync/pull/48) ([kbon](https://github.com/kbon))
- 3446 crm attribute [\#46](https://github.com/voxpupuli/puppet-corosync/pull/46) ([bitglue](https://github.com/bitglue))
- Add test for cs\_primitive utilization property [\#45](https://github.com/voxpupuli/puppet-corosync/pull/45) ([bitglue](https://github.com/bitglue))
- Adding Bundler Gemfile and .travis.yml [\#44](https://github.com/voxpupuli/puppet-corosync/pull/44) ([hunner](https://github.com/hunner))
- write some tests [\#43](https://github.com/voxpupuli/puppet-corosync/pull/43) ([bitglue](https://github.com/bitglue))
- make primitive utilization attributes managable [\#41](https://github.com/voxpupuli/puppet-corosync/pull/41) ([bitglue](https://github.com/bitglue))
- Added a cs\_location resource. [\#30](https://github.com/voxpupuli/puppet-corosync/pull/30) ([haraldsk](https://github.com/haraldsk))
- Only change /etc/defaults for corosync startup on Debian platforms [\#29](https://github.com/voxpupuli/puppet-corosync/pull/29) ([asachs](https://github.com/asachs))
- Delete an existing cib to start fresh [\#28](https://github.com/voxpupuli/puppet-corosync/pull/28) ([hunner](https://github.com/hunner))

## [0.1.0](https://github.com/voxpupuli/puppet-corosync/tree/0.1.0) (2012-10-16)

[Full Changelog](https://github.com/voxpupuli/puppet-corosync/compare/3b427df6c36b1d1ee8486330121879dc32563686...0.1.0)

**Merged pull requests:**

- Release 0.1.0 [\#27](https://github.com/voxpupuli/puppet-corosync/pull/27) ([hunner](https://github.com/hunner))
- Add documentation for new parameters and classes [\#26](https://github.com/voxpupuli/puppet-corosync/pull/26) ([hunner](https://github.com/hunner))
- Adds syntax highlighting [\#24](https://github.com/voxpupuli/puppet-corosync/pull/24) ([ody](https://github.com/ody))
- Introduce a new README [\#23](https://github.com/voxpupuli/puppet-corosync/pull/23) ([ody](https://github.com/ody))
- Remove things that are application specific. [\#22](https://github.com/voxpupuli/puppet-corosync/pull/22) ([ody](https://github.com/ody))
- Adding corosync::reprobe [\#21](https://github.com/voxpupuli/puppet-corosync/pull/21) ([hunner](https://github.com/hunner))
- Debug is a reserved ruby word. [\#20](https://github.com/voxpupuli/puppet-corosync/pull/20) ([hunner](https://github.com/hunner))
- Bugfix for monitoring standby [\#19](https://github.com/voxpupuli/puppet-corosync/pull/19) ([hunner](https://github.com/hunner))
- Add group resource [\#16](https://github.com/voxpupuli/puppet-corosync/pull/16) ([hunner](https://github.com/hunner))
- Add check/force online [\#14](https://github.com/voxpupuli/puppet-corosync/pull/14) ([hunner](https://github.com/hunner))
- Munge cs\_primitive ms\_metadata elements into strings [\#12](https://github.com/voxpupuli/puppet-corosync/pull/12) ([hunner](https://github.com/hunner))
- Enable setting ms\_metadata in cs\_primitive [\#10](https://github.com/voxpupuli/puppet-corosync/pull/10) ([hunner](https://github.com/hunner))
- Adding debug parameter to base class [\#9](https://github.com/voxpupuli/puppet-corosync/pull/9) ([hunner](https://github.com/hunner))
- Spec helper [\#8](https://github.com/voxpupuli/puppet-corosync/pull/8) ([hunner](https://github.com/hunner))
- Fix Typos [\#7](https://github.com/voxpupuli/puppet-corosync/pull/7) ([hunner](https://github.com/hunner))
- Update corosync::service to notify service [\#6](https://github.com/voxpupuli/puppet-corosync/pull/6) ([hunner](https://github.com/hunner))
- various bugfixes [\#5](https://github.com/voxpupuli/puppet-corosync/pull/5) ([branan](https://github.com/branan))
- Update style [\#2](https://github.com/voxpupuli/puppet-corosync/pull/2) ([ody](https://github.com/ody))

# 2016-09-16 - Release 5.0.0
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


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*