require Pathname.new(__FILE__).dirname.expand_path + 'cib_helper'

class Puppet::Provider::Crmsh < Puppet::Provider::CibHelper
  # Yep, that's right we are parsing XML...FUN! (It really wasn't that bad)
  require 'rexml/document'

  initvars
  commands :crm_attribute => 'crm_attribute'

  # Corosync takes a while to build the initial CIB configuration once the
  # service is started for the first time.  This provides us a way to wait
  # until we're up so we can make changes that don't disappear in to a black
  # hole.
  # rubocop:disable Style/ClassVars
  @@crmready = nil
  # rubocop:enable Style/ClassVars
  def self.ready?
    return true if @@crmready
    cmd =  [command(:crm_attribute), '--type', 'crm_config', '--query', '--name', 'dc-version']
    if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    else
      raw = Puppet::Util::Execution.execute(cmd, :failonfail => false, :combine => true)
      status = raw.exitstatus
    end
    if status == 0
      # rubocop:disable Style/ClassVars
      @@crmready = true
      # rubocop:enable Style/ClassVars
      # Sleeping a spare two since it seems that dc-version is returning before
      # It is really ready to take config changes, but it is close enough.
      # Probably need to find a better way to check for readiness.
      sleep 2
      return true
    else
      debug("Corosync not ready, retrying: #{raw}")
      return false
    end
  end

  def self.block_until_ready(timeout = 120)
    Timeout.timeout(timeout) do
      sleep 2 until ready?
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      # rubocop:disable Lint/AssignmentInCondition
      if res = resources[prov.name.to_s]
        # rubocop:enable Lint/AssignmentInCondition
        res.provider = prov
      end
    end
  end

  def exists?
    self.class.block_until_ready
    debug(@property_hash.inspect)
    !(@property_hash[:ensure] == :absent || @property_hash.empty?)
  end
end
