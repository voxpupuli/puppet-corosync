begin
  require 'puppet_x/voxpupuli/corosync/provider/crmsh'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync
  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/crmsh'
end

Puppet::Type.type(:cs_shadow).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  commands crm_shadow: 'crm_shadow'
  commands cibadmin: 'cibadmin'
  # Required for block_until_ready
  commands crm: 'crm'

  def self.instances
    block_until_ready
    []
  end

  def epoch
    get_epoch(resource.cib)
  end

  def get_epoch(cib = nil)
    cmd = [command(:cibadmin), '--query', '--xpath', '/cib', '-l', '-n']
    raw, status = PuppetX::Voxpupuli::Corosync::Provider::Crmsh.run_command_in_cib(cmd, cib, false)
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
    PuppetX::Voxpupuli::Corosync::Provider::Crmsh.sync_shadow_cib(@resource[:name])
  end
end
