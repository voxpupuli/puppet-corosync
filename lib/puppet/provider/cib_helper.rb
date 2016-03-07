class Puppet::Provider::CibHelper < Puppet::Provider
  # Yep, that's right we are parsing XML...FUN! (It really wasn't that bad)
  def self.run_command_in_cib(pcs_cmd, cib = nil, failonfail = true)
    custom_environment = if cib.nil?
                           {}
                         else
                           { :custom_environment => { 'CIB_shadow' => cib } }
                         end
    if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
      raw, status = Puppet::Util::SUIDManager.run_and_capture(pcs_cmd, nil, nil, custom_environment)
    else
      raw = Puppet::Util::Execution.execute(pcs_cmd, { :failonfail => failonfail }.merge(custom_environment))
      status = raw.exitstatus
    end
    return raw, status if status == 0 || failonfail == false
    raise Puppet::Error, "command #{pcs_cmd.join(' ')} failed"
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
end
