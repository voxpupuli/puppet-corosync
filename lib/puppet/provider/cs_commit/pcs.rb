require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_commit).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  commands :crm_shadow => 'crm_shadow'
  commands :cibadmin => 'cibadmin'
  # Required for block_until_ready
  commands :pcs => 'pcs'

  def self.instances
    block_until_ready
    []
  end

  def commit
    Puppet::Provider::Pacemaker.run_command_in_cib(['crm_shadow', '--force', '--commit', @resource[:name]])
    Puppet::Provider::Pacemaker.run_command_in_cib(['cibadmin', '--modify', '--xml-text', '<cib admin_epoch="admin_epoch++"/>'])
  end
end
