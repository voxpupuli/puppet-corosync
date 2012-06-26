require File.join(File.dirname(__FILE__), '..', 'corosync')
Puppet::Type.type(:cs_primitive).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no
        plan to abstract corosync/pacemaker vs. keepalived.  Primitives in
        Corosync are the thing we desire to monitor; websites, ipaddresses,
        databases, etc, etc.  Here we manage the creation and deletion of
        these primitives.  We will accept a hash for what Corosync calls
        operations and parameters.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm => 'crm'
  commands :crm_attribute => 'crm_attribute'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    doc = REXML::Document.new(raw)

    # We are obtaining four different sets of data in this block.  We obtain
    # key/value pairs for basic primitive information (which Corosync stores
    # in the configuration as "resources").  After getting that basic data we
    # descend into parameters, operations (which the config labels as
    # instance_attributes and operations), and metadata then generateembedded
    # hash structures of each entry.
    REXML::XPath.each(doc, '//primitive') do |e|

      primitive = {}
      items = e.attributes
      primitive.merge!({
        items['id'].to_sym => {
          :class    => items['class'],
          :type     => items['type'],
          :provider => items['provider']
        }
      })

      primitive[items['id'].to_sym][:parameters] = {}
      primitive[items['id'].to_sym][:operations] = {}
      primitive[items['id'].to_sym][:metadata] = {}

      if ! e.elements['instance_attributes'].nil?
        e.elements['instance_attributes'].each_element do |i|
          primitive[items['id'].to_sym][:parameters][(i.attributes['name'])] = i.attributes['value']
        end
      end

      if ! e.elements['meta_attributes'].nil?
        e.elements['meta_attributes'].each_element do |m|
          primitive[items['id'].to_sym][:metadata][(m.attributes['name'])] = m.attributes['value']
        end
      end

      if ! e.elements['operations'].nil?
        e.elements['operations'].each_element do |o|
          valids = o.attributes.reject do |k,v| k == 'id' end
          primitive[items['id'].to_sym][:operations][valids['name']] = {}
          valids.each do |k,v|
            primitive[items['id'].to_sym][:operations][valids['name']][k] = v if k != 'name'
          end
        end
      end
      primitive_instance = {
        :name            => primitive.first[0],
        :ensure          => :present,
        :primitive_class => primitive.first[1][:class],
        :provided_by     => primitive.first[1][:provider],
        :primitive_type  => primitive.first[1][:type],
        :parameters      => primitive.first[1][:parameters],
        :operations      => primitive.first[1][:operations],
        :metadata        => primitive.first[1][:metadata],
        :promotable      => :false,
        :provider        => self.name
      }
      primitive_instance[:promotable] = :true if e.parent.name == 'master'
      instances << new(primitive_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name            => @resource[:name],
      :ensure          => :present,
      :primitive_class => @resource[:primitive_class],
      :provided_by     => @resource[:provided_by],
      :primitive_type  => @resource[:primitive_type],
      :promotable      => @resource[:promotable]
    }
    @property_hash[:parameters] = @resource[:parameters] if ! @resource[:parameters].nil?
    @property_hash[:operations] = @resource[:operations] if ! @resource[:operations].nil?
    @property_hash[:metadata] = @resource[:metadata] if ! @resource[:metadata].nil?
  end

  # Unlike create we actually immediately delete the item.  Corosync forces us
  # to "stop" the primitive before we are able to remove it.
  def destroy
    cmd = [ command(:crm), 'resource', 'stop', @resource[:name] ]
    debug('Stopping primitive before removing it')
    Puppet::Util.execute(cmd)
    cmd = [ command(:crm), 'configure', 'delete', @resource[:name] ]
    debug('Revmoving primitive')
    Puppet::Util.execute(cmd)
    @property_hash.clear
  end

  # Getters that obtains the parameters and operations defined in our primitive
  # that have been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def parameters
    @property_hash[:parameters]
  end

  def operations
    @property_hash[:operations]
  end

  def metadata
    @property_hash[:metadata]
  end

  def promotable
    @property_hash[:promotable]
  end

  # Our setters for parameters and operations.  Setters are used when the
  # resource already exists so we just update the current value in the
  # property_hash and doing this marks it to be flushed.
  def parameters=(should)
    @property_hash[:parameters] = should
  end

  def operations=(should)
    @property_hash[:operations] = should
  end

  def metadata=(should)
    @property_hash[:metadata] = should
  end

  def promotable=(should)
    case should
    when :true
      @property_hash[:promotable] = should
    when :false
      @property_hash[:promotable] = should
      cmd = [ command(:crm), 'resource', 'stop', "ms_#{@resource[:name]}" ]
      cmd = [ command(:crm), 'configure', 'delete', "ms_#{@resource[:name]}" ]
      Puppet::Util.execute(cmd)
    end
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.  We have to do a bit of munging of our
  # operations and parameters hash to eventually flatten them into a string
  # that can be used by the crm command.
  def flush
    unless @property_hash.empty?
      unless @property_hash[:operations].empty?
        operations = ''
        @property_hash[:operations].each do |o|
          operations << "op #{o[0]} "
          o[1].each_pair do |k,v|
            operations << "#{k}=#{v} "
          end
        end
      end
      unless @property_hash[:parameters].empty?
        parameters = 'params '
        @property_hash[:parameters].each_pair do |k,v|
          parameters << "#{k}=#{v} "
        end
      end
      unless @property_hash[:metadata].empty?
        metadatas = 'meta '
        @property_hash[:metadata].each_pair do |k,v|
          metadatas << "#{k}=#{v} "
        end
      end
      updated = "primitive #{@property_hash[:name]} "
      updated << "#{@property_hash[:primitive_class]}:#{@property_hash[:provided_by]}:#{@property_hash[:primitive_type]} "
      updated << "#{operations} " unless operations.nil?
      updated << "#{parameters} " unless parameters.nil?
      updated << "#{metadatas} " unless metadatas.nil?
      if @property_hash[:promotable] == :true
        updated << "\n"
        updated << "ms ms_#{@property_hash[:name]} #{@property_hash[:name]}"
      end
      cmd = [ command(:crm), 'configure', 'load', 'update', '-' ]
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated)
        tmpfile.flush
        Puppet::Util.execute(cmd, :stdinfile => tmpfile.path.to_s)
      end
    end
  end
end
