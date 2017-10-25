begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync
  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_commit).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  commands cibadmin: 'cibadmin'
  # Required for block_until_ready
  commands pcs: 'pcs'

  def self.instances
    block_until_ready
    []
  end

  def commit
    cib_path = File.join(Puppet[:vardir], 'shadow.' + @resource[:name])
    PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib([command(:pcs), 'cluster', 'cib-push', cib_path, 'diff-against=' + cib_path + '.ori'])
    # We run the next command in the CIB directly by purpose:
    # We commit the shadow CIB with the admin_epoch it was created.
    PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib([command(:cibadmin), '--modify', '--xml-text', '<cib admin_epoch="admin_epoch++"/>'])
    # Next line is for indempotency
    PuppetX::Voxpupuli::Corosync::Provider::Pcs.sync_shadow_cib(@resource[:name], true)
  end
end
