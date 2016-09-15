begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync
  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_clone).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  desc 'Provider to add, delete, manipulate primitive clones.'

  commands pcs: 'pcs'
  commands cibadmin: 'cibadmin'

  mk_resource_methods

  defaultfor operatingsystem: [:fedora, :centos, :redhat]

  def change_clone_id(primitive, id, cib)
    xpath = "/cib/configuration/resources/clone[descendant::primitive[@id='#{primitive}']]"
    cmd = [command(:cibadmin), '--query', '--xpath', xpath]
    raw, = PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd, cib)
    doc = REXML::Document.new(raw)
    if doc.root.attributes['id'] != id
      doc.root.attributes['id'] = id
      cmd = [command(:cibadmin), '--replace', '--xpath', xpath, '--xml-text', doc.to_s.chop]
      PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd, cib)
    end
  end

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['resources'].each_element('clone') do |e|
      primitive_id = e.elements['primitive'].attributes['id']
      items = nvpairs_to_hash(e.elements['meta_attributes'])

      clone_instance = {
        name:              e.attributes['id'],
        ensure:            :present,
        primitive:         primitive_id,
        clone_max:         items['clone-max'],
        clone_node_max:    items['clone-node-max'],
        notify_clones:     items['notify'],
        globally_unique:   items['globally-unique'],
        ordered:           items['ordered'],
        interleave:        items['interleave'],
        existing_resource: :true
      }
      instances << new(clone_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name:              @resource[:name],
      ensure:            :present,
      primitive:         @resource[:primitive],
      clone_max:         @resource[:clone_max],
      clone_node_max:    @resource[:clone_node_max],
      notify_clones:     @resource[:notify_clones],
      globally_unique:   @resource[:globally_unique],
      ordered:           @resource[:ordered],
      interleave:        @resource[:interleave],
      existing_resource: :false
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug 'Removing clone'
    PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib([command(:pcs), 'resource', 'unclone', @resource[:name]], @resource[:cib])
    @property_hash.clear
  end

  def exists?
    @property_hash[:existing_resource] == :true
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      if @property_hash[:existing_resource] == :false
        debug 'Creating clone resource'
      else
        debug 'Updating clone resource'
        # pcs versions earlier than 0.9.116 do not allow updating a cloned
        # resource. Being conservative, we will unclone then create a new clone
        # with the new parameters.
        PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib([command(:pcs), 'resource', 'unclone', @resource[:primitive]], @resource[:cib])
      end
      cmd = [command(:pcs), 'resource', 'clone', (@property_hash[:primitive]).to_s]
      cmd << "clone-max=#{@property_hash[:clone_max]}" if @property_hash[:clone_max]
      cmd << "clone-node-max=#{@property_hash[:clone_node_max]}" if @property_hash[:clone_node_max]
      cmd << "notify=#{@property_hash[:notify_clones]}" if @property_hash[:notify_clones]
      cmd << "globally-unique=#{@property_hash[:globally_unique]}" if @property_hash[:globally_unique]
      cmd << "ordered=#{@property_hash[:ordered]}" if @property_hash[:ordered]
      cmd << "interleave=#{@property_hash[:interleave]}" if @property_hash[:interleave]
      PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd, @resource[:cib])
      change_clone_id(@property_hash[:primitive], @property_hash[:name], @resource[:cib])
    end
  end
end
