require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_shadow).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  commands :crm_shadow => 'crm_shadow'
  commands :cibadmin => 'cibadmin'

  def self.instances
    block_until_ready(120, 15)
    []
  end

  def epoch
    get_epoch(resource.cib)
  end

  def get_epoch(cib=nil)
    cmd = [ command(:cibadmin), '--query', '--xpath', '/cib', '-l', '-n' ]
    if cib.nil?
      debug('epoch for main cib')
    else
      debug('epoch for other cib')
    end
    raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd, cib, false)
    if status != 0
      return :absent
    else
    doc = REXML::Document.new(raw)
    debug("#{REXML::XPath.first(doc, '/cib').attributes['epoch']}")
    currentvalue = REXML::XPath.first(doc, '/cib').attributes['epoch']
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
