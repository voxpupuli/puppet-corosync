require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'cib_helper'

Puppet::Type.type(:cs_commit).provide(:pcs, :parent => Puppet::Provider::CibHelper) do
  commands :crm_shadow => 'crm_shadow'
  commands :cibadmin => 'cibadmin'
  # Required for block_until_ready
  commands :pcs => 'pcs'

  def self.instances
    block_until_ready
    []
  end

  def commit
    crm_shadow('--force', '--commit', @resource[:name])
    cibadmin('--modify', '--xml-text', '<cib admin_epoch="admin_epoch++"/>')
  end
end
