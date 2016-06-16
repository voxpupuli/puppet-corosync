begin
  require 'puppet_x/voxpupuli/corosync/provider'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync
  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider'
end

class PuppetX::Voxpupuli::Corosync::Provider::CibHelper < Puppet::Provider
  # Yep, that's right we are parsing XML...FUN! (It really wasn't that bad)
  def self.run_command_in_cib(cmd, cib = nil, failonfail = true)
    custom_environment = if cib.nil?
                           { combine: true }
                         else
                           { combine: true, custom_environment: { 'CIB_shadow' => cib } }
                         end
    debug("Executing #{cmd} in the CIB") if cib.nil?
    debug("Executing #{cmd} in the shadow CIB \"#{cib}\"") unless cib.nil?
    if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, nil, nil, custom_environment)
    else
      raw = Puppet::Util::Execution.execute(cmd, { failonfail: failonfail }.merge(custom_environment))
      status = raw.exitstatus
    end
    return raw, status if status == 0 || failonfail == false
    raise Puppet::Error, "Command #{cmd.join(' ')} failed" if cib.nil?
    raise Puppet::Error, "Command #{cmd.join(' ')} failed in the shadow CIB \"#{cib}\"" unless cib.nil?
  end

  # given an XML element containing some <nvpair>s, return a hash. Return an
  # empty hash if `e` is nil.
  def self.nvpairs_to_hash(e)
    return {} if e.nil?

    hash = {}
    e.each_element do |i|
      hash[i.attributes['name']] = i.attributes['value'].strip
    end

    hash
  end

  def self.sync_shadow_cib(cib, failondeletefail = false)
    run_command_in_cib(['crm_shadow', '--force', '--delete', cib], nil, failondeletefail)
    run_command_in_cib(['crm_shadow', '--batch', '--create', cib])
  end
end
