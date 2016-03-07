require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'crmsh'

Puppet::Type.type(:cs_commit).provide(:crm, :parent => Puppet::Provider::Crmsh) do
  commands :crm_shadow => 'crm_shadow'
  commands :cibadmin => 'cibadmin'
  # Required for block_until_ready
  commands :crm => 'crm'

  def self.instances
    block_until_ready
    []
  end

  def commit
    Puppet::Provider::Pacemaker.run_command_in_cib(['crm_shadow', '--force', '--commit', @resource[:name]])
    Puppet::Provider::Pacemaker.run_command_in_cib(['cibadmin', '--modify', '--xml-text', '<cib admin_epoch="admin_epoch++"/>'])
  end
end
