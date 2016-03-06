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
end
