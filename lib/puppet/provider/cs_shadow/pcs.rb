require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'cib_helper'

Puppet::Type.type(:cs_shadow).provide(:crm_shadow, :parent => Puppet::Provider::CibHelper) do
  commands :crm_shadow => 'crm_shadow'
  commands :cibadmin => 'cibadmin'
  # Required for block_until_ready
  commands :pcs => 'pcs'

  def self.instances
    block_until_ready
    []
  end

  def epoch
    get_epoch(resource.cib)
  end

  def get_epoch(cib = nil)
    cmd = [command(:cibadmin), '--query', '--xpath', '/cib', '-l', '-n']
    raw, status = Puppet::Provider::CibHelper.run_command_in_cib(cmd, cib, false)
    return :absent if status != 0
    doc = REXML::Document.new(raw)
    current_epoch = REXML::XPath.first(doc, '/cib').attributes['epoch']
    current_admin_epoch = REXML::XPath.first(doc, '/cib').attributes['admin_epoch']
    currentvalue = "#{current_admin_epoch}.#{current_epoch}" if current_epoch && current_admin_epoch
    currentvalue || :absent
  end

  def insync?(cib)
    get_epoch == get_epoch(cib)
  end

  def sync(_cib)
    begin
      crm_shadow('--force', '--delete', @resource[:name])
    rescue
      nil
      # If the CIB doesn't exist, we don't care.
    end
    crm_shadow('--batch', '--create', @resource[:name])
  end
end
