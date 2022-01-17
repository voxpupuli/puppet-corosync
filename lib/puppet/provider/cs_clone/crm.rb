# frozen_string_literal: true

begin
  require 'puppet_x/voxpupuli/corosync/provider/crmsh'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/crmsh'
end

Puppet::Type.type(:cs_clone).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  desc 'Provider to add, delete, manipulate primitive clones.'

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.
  commands crm: 'crm'
  commands crm_attribute: 'crm_attribute'

  mk_resource_methods

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:crm), 'configure', 'show', 'xml']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//resources//clone') do |e|
      items = nvpairs_to_hash(e.elements['meta_attributes'])

      clone_instance = {
        name: e.attributes['id'],
        ensure: :present,
        clone_max: items['clone-max'],
        clone_node_max: items['clone-node-max'],
        notify_clones: items['notify'],
        globally_unique: items['globally-unique'],
        ordered: items['ordered'],
        interleave: items['interleave'],
        existing_resource: :true
      }

      clone_instance[:primitive] = e.elements['primitive'].attributes['id'] if e.elements['primitive']

      clone_instance[:group] = e.elements['group'].attributes['id'] if e.elements['group']
      instances << new(clone_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      primitive: @resource[:primitive],
      clone_max: @resource[:clone_max],
      clone_node_max: @resource[:clone_node_max],
      notify_clones: @resource[:notify_clones],
      globally_unique: @resource[:globally_unique],
      ordered: @resource[:ordered],
      interleave: @resource[:interleave],
      cib: @resource[:cib],
      existing_resource: :false
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing clone')
    cmd = [command(:crm), '-w', 'resource', 'stop', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib], false)
    cmd = [command(:crm), 'configure', 'delete', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib])
    @property_hash.clear
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    return if @property_hash.empty?

    if @resource.should(:primitive)
      target = @resource.should(:primitive)
    elsif @resource.should(:group)
      target = @resource.should(:group)
    else
      raise Puppet::Error, 'No primitive or group'
    end
    updated = 'clone '
    updated << "#{@resource.value(:name)} "
    updated << "#{target} "
    meta = []
    {
      clone_max: 'clone-max',
      clone_node_max: 'clone-node-max',
      notify_clones: 'notify',
      globally_unique: 'globally-unique',
      ordered: 'ordered',
      interleave: 'interleave'
    }.each do |property, clone_property|
      meta << "#{clone_property}=#{@resource.should(property)}" unless @resource.should(property) == :absent
    end
    updated << 'meta ' << meta.join(' ') unless meta.empty?
    debug "Update: #{updated}"
    Tempfile.open('puppet_crm_update') do |tmpfile|
      tmpfile.write(updated)
      tmpfile.flush
      cmd = [command(:crm), 'configure', 'load', 'update', tmpfile.path.to_s]
      self.class.run_command_in_cib(cmd, @resource.value(:cib))
    end
  end
end
