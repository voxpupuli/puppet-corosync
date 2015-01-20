require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_clone).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Provider to add, delete, manipulate primitive clones.'

  commands :pcs => 'pcs'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  # given an XML element containing some <nvpair>s, return a hash. Return an
  # empty hash if `e` is nil.
  def self.nvpairs_to_hash(e)
    return {} if e.nil?

    hash = {}
    e.each_element do |i|
      hash[(i.attributes['name'])] = i.attributes['value'].strip
    end

    hash
  end

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['resources'].each_element('clone') do |e|
      primitive_id = e.elements['primitive'].attributes['id']
      items = nvpairs_to_hash(e.elements['meta_attributes'])

      clone_instance = {
        :name              => e.attributes['id'],
        :ensure            => :present,
        :primitive         => primitive_id,
        :clone_max         => items['clone-max'],
        :clone_node_max    => items['clone-node-max'],
        :notify_clones     => items['notify'],
        :globally_unique   => items['globally-unique'],
        :ordered           => items['ordered'],
        :interleave        => items['interleave'],
        :existing_resource => :true,
      }
      instances << new(clone_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name              => @resource[:primitive]+'-clone',
      :ensure            => :present,
      :primitive         => @resource[:primitive],
      :clone_max         => @resource[:clone_max],
      :clone_node_max    => @resource[:clone_node_max],
      :notify_clones     => @resource[:notify_clones],
      :globally_unique   => @resource[:globally_unique],
      :ordered           => @resource[:ordered],
      :interleave        => @resource[:interleave],
      :cib               => @resource[:cib],
      :existing_resource => :false,
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing clone')
    Puppet::Provider::Pacemaker::run_pcs_command([command(:pcs), 'resource', 'unclone', @resource[:name]])
    @property_hash.clear
  end
  #
  # Getter that obtains the our service that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def primitive
    @property_hash[:primitive]
  end

  # Getter that obtains the our clone_max that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def clone_max
    @property_hash[:clone_max]
  end

  def clone_node_max
    @property_hash[:clone_node_max]
  end

  def notify_clones
    @property_hash[:notify_clones]
  end

  def globally_unique
    @property_hash[:globally_unique]
  end

  def ordered
    @property_hash[:ordered]
  end

  def interleave
    @property_hash[:interleave]
  end

  # Our setters.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.

  def primitive=(should)
    @property_hash[:primitive] = should
  end

  def clone_max=(should)
    @property_hash[:clone_max] = should
  end

  def clone_node_max=(should)
    @property_hash[:clone_node_max] = should
  end

  def notify_clones=(should)
    @property_hash[:notify_clones] = should
  end

  def globally_unique=(should)
    @property_hash[:globally_unique] = should
  end

  def ordered=(should)
    @property_hash[:ordered] = should
  end

  def interleave=(should)
    @property_hash[:interleave] = should
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
        debug ('Creating clone resource')
        cmd = [ command(:pcs), 'resource', 'clone', "#{@property_hash[:primitive]}" ]
        cmd << "clone-max=#{@property_hash[:clone_max]}" if @property_hash[:clone_max]
        cmd << "clone-node-max=#{@property_hash[:clone_node_max]}" if @property_hash[:clone_node_max]
        cmd << "notify=#{@property_hash[:notify_clones]}" if @property_hash[:notify_clones]
        cmd << "globally-unique=#{@property_hash[:globally_unique]}" if @property_hash[:globally_unique]
        cmd << "ordered=#{@property_hash[:ordered]}" if @property_hash[:ordered]
        cmd << "interleave=#{@property_hash[:interleave]}" if @property_hash[:interleave]
        raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
      else
        debug ('Updating clone resource')
        # pcs versions earlier than 0.9.116 do not allow updating a cloned
        # resource. Being conservative, we will unclone then create a new clone
        # with the new parameters.
        Puppet::Provider::Pacemaker::run_pcs_command([command(:pcs), 'resource', 'unclone', @resource[:primitive]])
        cmd = [ command(:pcs), 'resource', 'clone', "#{@property_hash[:primitive]}" ]
        cmd << "clone-max=#{@property_hash[:clone_max]}" if @property_hash[:clone_max]
        cmd << "clone-node-max=#{@property_hash[:clone_node_max]}" if @property_hash[:clone_node_max]
        cmd << "notify=#{@property_hash[:notify_clones]}" if @property_hash[:notify_clones]
        cmd << "globally-unique=#{@property_hash[:globally_unique]}" if @property_hash[:globally_unique]
        cmd << "ordered=#{@property_hash[:ordered]}" if @property_hash[:ordered]
        cmd << "interleave=#{@property_hash[:interleave]}" if @property_hash[:interleave]
        raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
      end
    end
  end
end

