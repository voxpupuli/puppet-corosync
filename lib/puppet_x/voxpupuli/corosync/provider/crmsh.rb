# frozen_string_literal: true
begin
  require 'puppet_x/voxpupuli/corosync/provider'
  require 'puppet_x/voxpupuli/corosync/provider/cib_helper'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider'
  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/cib_helper'
end

class PuppetX::Voxpupuli::Corosync::Provider::Crmsh < PuppetX::Voxpupuli::Corosync::Provider::CibHelper
  initvars
  commands cibadmin: 'cibadmin'
  commands crm_attribute: 'crm_attribute'
  commands crm: 'crm'

  # Corosync takes a while to build the initial CIB configuration once the
  # service is started for the first time.  This provides us a way to wait
  # until we're up so we can make changes that don't disappear in to a black
  # hole.
  # rubocop:disable Style/ClassVars
  @@crmready = nil
  # rubocop:enable Style/ClassVars
  def self.ready?(shadow_cib)
    return true if @@crmready

    cmd =  [command(:crm_attribute), '--type', 'crm_config', '--query', '--name', 'dc-version']
    raw, status = run_command_in_cib(cmd, nil, false)
    if status.zero?
      # Wait until epoch is not 0.0.
      # On empty cluster it will stay 0.0 so there you wait the 60 seconds.
      # On new nodes you wait just enough time to allow the node to join the cluster.
      # That should not happen often, so it is acceptable to sleep up to 60 seconds here.
      cib_epoch = wait_for_nonzero_epoch(shadow_cib)

      warn("Pacemaker: CIB epoch is #{cib_epoch}. You can ignore this message if you are bootstrapping a new cluster.") if cib_epoch == '0.0'

      if cib_epoch == :absent
        debug('Corosync is not ready (no CIB available)')
        return false
      end

      # rubocop:disable Style/ClassVars
      @@crmready = true
      # rubocop:enable Style/ClassVars

      debug("Corosync is ready, CIB epoch is #{cib_epoch}.")
      true
    else
      debug("Corosync not ready, retrying: #{raw}")
      false
    end
  end

  def self.block_until_ready(timeout = 120, shadow_cib = false)
    Timeout.timeout(timeout, shadow_cib) do
      sleep 2 until ready?(shadow_cib)
    end
  end

  def self.get_epoch(cib = nil)
    cmd = [command(:cibadmin), '--query', '--xpath', '/cib', '-l', '-n']
    _get_epoch(cmd, cib)
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

  def self.run_command_in_cib(cmd, cib = nil, failonfail = true)
    custom_environment = if cib.nil?
                           { combine: true }
                         else
                           { combine: true, custom_environment: { 'CIB_shadow' => cib } }
                         end
    _run_command_in_cib(cmd, cib, failonfail, custom_environment)
  end

  def self.sync_shadow_cib(cib, failondeletefail = false)
    run_command_in_cib(['crm_shadow', '--force', '--delete', cib], nil, failondeletefail)
    run_command_in_cib(['crm_shadow', '--batch', '--create', cib])
  end

  def exists?
    self.class.block_until_ready
    debug(@property_hash.inspect)
    !(@property_hash[:ensure] == :absent || @property_hash.empty?)
  end
end
