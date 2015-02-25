require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'crmsh'

Puppet::Type.type(:cs_clone).provide(:crm, :parent => Puppet::Provider::Crmsh) do
  desc 'Provider to add, delete, manipulate primitive clones.'

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.
  commands :crm => 'crm'
  commands :crm_attribute => 'crm_attribute'

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

    cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    if Puppet::PUPPETVERSION.to_f < 3.4
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    else
      raw = Puppet::Util::Execution.execute(cmd)
      status = raw.exitstatus
    end
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['resources'].each_element('clone') do |e|
      primitive_id = e.elements['primitive'].attributes['id']
      items = nvpairs_to_hash(e.elements['meta_attributes'])

      clone_instance = {
        :name            => e.attributes['id'],
        :ensure          => :present,
        :primitive       => primitive_id,
        :clone_max       => items['clone-max'],
        :clone_node_max  => items['clone-node-max'],
        :notify_clones   => items['notify'],
        :globally_unique => items['globally-unique'],
        :ordered         => items['ordered'],
        :interleave      => items['interleave'],
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
      :name       => @resource[:name],
      :ensure     => :present,
      :primitive       => @resource[:primitive],
      :clone_max       => @resource[:clone_max],
      :clone_node_max  => @resource[:clone_node_max],
      :notify_clones   => @resource[:notify_clones],
      :globally_unique => @resource[:globally_unique],
      :ordered         => @resource[:ordered],
      :interleave      => @resource[:interleave],
      :cib             => @resource[:cib],
      :existing_resource => :false,
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing clone')
    crm('configure', 'delete', @resource[:name])
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

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      if @property_hash[:existing_resource] == :false
        debug ('Creating clone resource')
        updated = "clone "
        updated << "#{@property_hash[:name]} "
        updated << "#{@property_hash[:primitive]} "
        meta = ""
        meta << "clone-max=#{@property_hash[:clone_max]} " if @property_hash[:clone_max]
        meta << "clone-node-max=#{@property_hash[:clone_node_max]} " if @property_hash[:clone_node_max]
        meta << "notify=#{@property_hash[:notify_clones]} " if @property_hash[:notify_clones]
        meta << "globally-unique=#{@property_hash[:globally_unique]} " if @property_hash[:globally_unique]
        meta << "ordered=#{@property_hash[:ordered]} " if @property_hash[:ordered]
        meta << "interleave=#{@property_hash[:interleave]}" if @property_hash[:interleave]
        updated << "meta " << meta if not meta.empty?
        Tempfile.open('puppet_crm_update') do |tmpfile|
          tmpfile.write(updated)
          tmpfile.flush
          ENV["CIB_shadow"] = @resource[:cib]
          crm('configure', 'load', 'update', tmpfile.path.to_s)
        end
      else
        debug ('Updating clone resource')
        updated = "resource meta "
        updated << "#{@property_hash[:name]} "
        meta = "set "
        meta << "clone-max=#{@property_hash[:clone_max]} " if @property_hash[:clone_max]
        meta << "clone-node-max=#{@property_hash[:clone_node_max]} " if @property_hash[:clone_node_max]
        meta << "notify=#{@property_hash[:notify_clones]} " if @property_hash[:notify_clones]
        meta << "globally-unique=#{@property_hash[:globally_unique]} " if @property_hash[:globally_unique]
        meta << "ordered=#{@property_hash[:ordered]} " if @property_hash[:ordered]
        meta << "interleave=#{@property_hash[:interleave]}" if @property_hash[:interleave]
        updated << meta if not meta.empty?
        Tempfile.open('puppet_crm_update') do |tmpfile|
          tmpfile.write(updated)
          tmpfile.flush
          ENV["CIB_shadow"] = @resource[:cib]
          crm('configure', 'load', 'update', tmpfile.path.to_s)
        end
      end
    end
  end
end

