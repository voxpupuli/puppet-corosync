# frozen_string_literal: true

begin
  require 'puppet_x/voxpupuli/corosync/provider/crmsh'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/crmsh'
end

Puppet::Type.type(:cs_group).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  desc 'Provider to add, delete, manipulate primitive groups.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands crm: '/usr/sbin/crm'

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:crm), 'configure', 'show', 'xml']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//group') do |e|
      primitives = []

      unless e.elements['primitive'].nil?
        e.each_element do |p|
          primitives << p.attributes['id']
        end
      end

      group_instance = {
        name: e.attributes['id'],
        ensure: :present,
        primitives: primitives,
        provider: name
      }
      instances << new(group_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      primitives: Array(@resource[:primitives])
    }
    @property_hash[:cib] = @resource[:cib] unless @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item but first, like primitives,
  # we need to stop the group.
  def destroy
    debug('Stopping group before removing it')
    cmd = [command(:crm), '-w', 'resource', 'stop', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib], false)
    debug('Removing group')
    cmd = [command(:crm), 'configure', 'delete', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib])
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitives
    @property_hash[:primitives]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def primitives=(should)
    @property_hash[:primitives] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    return if @property_hash.empty?

    updated = 'group '
    updated << "#{@property_hash[:name]} #{Array(@property_hash[:primitives]).join(' ')}"
    debug("Loading update: #{updated}")
    Tempfile.open('puppet_crm_update') do |tmpfile|
      tmpfile.write(updated)
      tmpfile.flush
      cmd = [command(:crm), 'configure', 'load', 'update', tmpfile.path.to_s]
      self.class.run_command_in_cib(cmd, @resource[:cib])
    end
  end
end
