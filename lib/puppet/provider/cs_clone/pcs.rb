# frozen_string_literal: true
begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_clone).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  desc 'Provider to add, delete, manipulate primitive clones.'

  commands pcs: 'pcs'
  commands cibadmin: 'cibadmin'

  mk_resource_methods

  defaultfor operatingsystem: %i[fedora centos redhat]

  def change_clone_id(type, primitive, id, cib)
    xpath = "/cib/configuration/resources/clone[descendant::#{type}[@id='#{primitive}']]"
    cmd = [command(:cibadmin), '--query', '--xpath', xpath]
    raw, = self.class.run_command_in_cib(cmd, cib)
    doc = REXML::Document.new(raw)
    return unless doc.root.attributes['id'] != id

    doc.root.attributes['id'] = id
    cmd = [command(:cibadmin), '--replace', '--xpath', xpath, '--xml-text', doc.to_s.chop]
    self.class.run_command_in_cib(cmd, cib)
  end

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
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
        interleave: items['interleave']
      }

      if e.elements['primitive']
        primitive_id = e.elements['primitive'].attributes['id']
        clone_instance[:primitive] = primitive_id
        clone_instance[:existing_clone_element] = primitive_id
      end

      if e.elements['group']
        group_id = e.elements['group'].attributes['id']
        clone_instance[:group] = group_id
        clone_instance[:existing_clone_element] = group_id
      end

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
      group: @resource[:group],
      clone_max: @resource[:clone_max],
      clone_node_max: @resource[:clone_node_max],
      notify_clones: @resource[:notify_clones],
      globally_unique: @resource[:globally_unique],
      ordered: @resource[:ordered],
      interleave: @resource[:interleave]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug 'Removing clone'
    self.class.run_command_in_cib([command(:pcs), 'resource', 'unclone', @resource[:name]], @resource[:cib])
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
      target_type = 'primitive'
    elsif @resource.should(:group)
      target = @resource.should(:group)
      target_type = 'group'
    else
      raise Puppet::Error, 'No primitive or group'
    end
    if @property_hash[:existing_clone_element].nil?
      debug 'Creating clone resource'
    else
      debug 'Updating clone resource'
      # pcs versions earlier than 0.9.116 do not allow updating a cloned
      # resource. Being conservative, we will unclone then create a new clone
      # with the new parameters.
      self.class.run_command_in_cib([command(:pcs), 'resource', 'unclone', @property_hash[:existing_clone_element]], @resource.value(:cib))
    end
    cmd = [command(:pcs), 'resource', 'clone', target.to_s]
    {
      clone_max: 'clone-max',
      clone_node_max: 'clone-node-max',
      notify_clones: 'notify',
      globally_unique: 'globally-unique',
      ordered: 'ordered',
      interleave: 'interleave'
    }.each do |property, clone_property|
      cmd << "#{clone_property}=#{@resource.should(property)}" unless @resource.should(property) == :absent
    end
    self.class.run_command_in_cib(cmd, @resource.value(:cib))
    change_clone_id(target_type, target, @resource.value(:name), @resource.value(:cib))
  end
end
