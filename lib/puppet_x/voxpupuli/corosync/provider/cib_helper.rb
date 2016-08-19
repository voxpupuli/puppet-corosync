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
  require 'rexml/document'

  def self.run_command_in_cib(cmd, cib = nil, failonfail = true)
    custom_environment = if cib.nil?
                           { combine: true }
                         else
                           { combine: true, custom_environment: { 'CIB_shadow' => cib } }
                         end
    debug("Executing #{cmd} in the CIB") if cib.nil?
    debug("Executing #{cmd} in the shadow CIB \"#{cib}\"") unless cib.nil?
    raw = Puppet::Util::Execution.execute(cmd, { failonfail: failonfail }.merge(custom_environment))
    status = raw.exitstatus
    return raw, status if status.zero? || failonfail == false
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

  def self.get_epoch(cib = nil)
    cmd = [command(:cibadmin), '--query', '--xpath', '/cib', '-l', '-n']
    raw, status = run_command_in_cib(cmd, cib, false)
    return :absent if status.nonzero?
    doc = REXML::Document.new(raw)
    current_epoch = REXML::XPath.first(doc, '/cib').attributes['epoch']
    current_admin_epoch = REXML::XPath.first(doc, '/cib').attributes['admin_epoch']
    currentvalue = "#{current_admin_epoch}.#{current_epoch}" if current_epoch && current_admin_epoch
    currentvalue || :absent
  end

  # This function waits for the epoch to be different than 0.0
  # different than :absent. Returns the value of the epoch as soon an it is present and
  # different that 0.0 or eventually returns the value after a certain time.
  def self.wait_for_nonzero_epoch(shadow_cib)
    begin
      Timeout.timeout(60) do
        if shadow_cib
          epoch = get_epoch
          while epoch == :absent || epoch.start_with?('0.')
            sleep 2
            epoch = get_epoch
          end
        else
          sleep 2 while ['0.0', :absent].include?(get_epoch)
        end
      end
    rescue Timeout::Error
      debug('Timeout reached while fetching a relevant epoch')
    end
    get_epoch
  end
end
