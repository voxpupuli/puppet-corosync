require 'puppet_x/voxpupuli/corosync/provider/crmsh'

Puppet::Type.type(:cs_commit).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  commands crm_shadow: 'crm_shadow'
  commands cibadmin: 'cibadmin'
  # Required for block_until_ready
  commands crm: 'crm'

  def self.instances
    block_until_ready
    []
  end

  def commit
    PuppetX::Voxpupuli::Corosync::Provider::Crmsh.run_command_in_cib(['crm_shadow', '--force', '--commit', @resource[:name]])
    # We run the next command in the CIB directly by purpose:
    # We commit the shadow CIB with the admin_epoch it was created.
    PuppetX::Voxpupuli::Corosync::Provider::Crmsh.run_command_in_cib(['cibadmin', '--modify', '--xml-text', '<cib admin_epoch="admin_epoch++"/>'])
    # Next line is for indempotency
    PuppetX::Voxpupuli::Corosync::Provider::Crmsh.sync_shadow_cib(@resource[:name], true)
  end
end
