require 'puppet_x/voxpupuli/corosync/provider/pcs'

Puppet::Type.type(:cs_commit).provide(:pcs, parent: PuppetX::VoxPupuli::Corosync::Provider::Pcs) do
  commands crm_shadow: 'crm_shadow'
  commands cibadmin: 'cibadmin'
  # Required for block_until_ready
  commands pcs: 'pcs'

  def self.instances
    block_until_ready
    []
  end

  def commit
    PuppetX::VoxPupuli::Corosync::Provider::Pcs.run_command_in_cib(['crm_shadow', '--force', '--commit', @resource[:name]])
    PuppetX::VoxPupuli::Corosync::Provider::Pcs.run_command_in_cib(['cibadmin', '--modify', '--xml-text', '<cib admin_epoch="admin_epoch++"/>'])
  end
end
