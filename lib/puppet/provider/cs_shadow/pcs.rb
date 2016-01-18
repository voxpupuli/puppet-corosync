require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_shadow).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  commands :crm_shadow => 'crm_shadow'
  commands :cibadmin => 'cibadmin'

  def self.instances
    block_until_ready(120)
    []
  end

  def epoch
    get_epoch(resource.cib)
  end

  def get_epoch(cib=nil)
    cmd = [ command(:cibadmin), '--query', '--xpath', '/cib', '-l', '-n' ]
    raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd, cib, false)
    if status != 0
      return :absent
    else
    doc = REXML::Document.new(raw)
    current_epoch = REXML::XPath.first(doc, '/cib').attributes['epoch']
    current_admin_epoch = REXML::XPath.first(doc, '/cib').attributes['admin_epoch']
    if current_epoch and current_admin_epoch
      currentvalue = "#{current_admin_epoch}.#{current_epoch}"
    end
    currentvalue || :absent
    end
  end

  def insync?(cib)
    get_epoch() == get_epoch(cib)
  end

  def sync(cib)
    begin
      crm_shadow('--force', '--delete', @resource[:name])
    rescue => e
      # If the CIB doesn't exist, we don't care.
    end
    crm_shadow('--batch', '--create', @resource[:name])
  end
end
