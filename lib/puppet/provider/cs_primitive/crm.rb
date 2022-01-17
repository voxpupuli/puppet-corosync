# frozen_string_literal: true

begin
  require 'puppet_x/voxpupuli/corosync/provider/crmsh'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/crmsh'
end

Puppet::Type.type(:cs_primitive).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  desc 'Specific provider for a rather specific type since I currently have no
        plan to abstract corosync/pacemaker vs. keepalived.  Primitives in
        Corosync are the thing we desire to monitor; websites, ipaddresses,
        databases, etc, etc.  Here we manage the creation and deletion of
        these primitives.  We will accept a hash for what Corosync calls
        operations and parameters.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands crm: 'crm'

  # given an XML element (a <primitive> from cibadmin), produce a hash suitible
  # for creating a new provider instance.
  def self.element_to_hash(e)
    hash = {
      primitive_class: e.attributes['class'],
      primitive_type: e.attributes['type'],
      provided_by: e.attributes['provider'],
      name: e.attributes['id'].to_sym,
      ensure: :present,
      provider: name,
      parameters: nvpairs_to_hash(e.elements['instance_attributes']),
      operations: [],
      utilization: nvpairs_to_hash(e.elements['utilization']),
      metadata: nvpairs_to_hash(e.elements['meta_attributes']),
      existing_metadata: nvpairs_to_hash(e.elements['meta_attributes']),
      ms_metadata: {},
    }

    operations = e.elements['operations']
    operations&.each_element do |o|
      valids = o.attributes.reject { |k, _v| k == 'id' }
        name = valids['name'].to_s
        operation = {}
        operation[name] = {}
        valids.each do |k, v|
          operation[name][k] = v.to_s if k != 'name'
        end
        o.elements['instance_attributes']&.each_element do |i|
          operation[name][i.attributes['name']] = i.attributes['value']
        end
        hash[:operations] << operation
    end

    hash
  end

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:crm), 'configure', 'show', 'xml']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//primitive') do |e|
      instances << new(element_to_hash(e))
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      primitive_class: @resource[:primitive_class],
      provided_by: @resource[:provided_by],
      primitive_type: @resource[:primitive_type],
    }
    @property_hash[:parameters] = @resource[:parameters] unless @resource[:parameters].nil?
    @property_hash[:operations] = @resource[:operations] unless @resource[:operations].nil?
    @property_hash[:utilization] = @resource[:utilization] unless @resource[:utilization].nil?
    @property_hash[:metadata] = @resource[:metadata] unless @resource[:metadata].nil?
    @property_hash[:cib] = @resource[:cib] unless @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item.  Corosync forces us
  # to "stop" the primitive before we are able to remove it.
  def destroy
    debug('Stopping primitive before removing it')
    cmd = [command(:crm), 'resource', 'stop', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib])
    debug('Removing primitive')
    cmd = [command(:crm), 'configure', 'delete', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib])
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

  def utilization
    @property_hash[:utilization]
  end

  def metadata
    @property_hash[:metadata]
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

  def utilization=(should)
    @property_hash[:utilization] = should
  end

  def metadata=(should)
    @property_hash[:metadata] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.  We have to do a bit of munging of our
  # operations and parameters hash to eventually flatten them into a string
  # that can be used by the crm command.
  def flush
    return if @property_hash.empty?

    unless @property_hash[:operations].empty?
      operations = ''
      @property_hash[:operations].each do |o|
        op_name = o.keys.first
        operations << "op #{op_name} "
        o.values.first.each_pair do |k, v|
          operations << "#{k}=#{v} "
        end
      end
    end
    if @resource&.instance_of?(:cs_primitive) && @resource[:unmanaged_metadata]
      @resource[:unmanaged_metadata].each do |parameter_name|
        @property_hash[:metadata][parameter_name] = @property_hash[:existing_metadata]['target-role'] if @property_hash[:existing_metadata] && @property_hash[:existing_metadata][parameter_name]
      end
    end
    unless @property_hash[:parameters].empty?
      parameters = 'params '
      @property_hash[:parameters].each_pair do |k, v|
        parameters << "'#{k}=#{v}' "
      end
    end
    unless @property_hash[:utilization].empty?
      utilization = 'utilization '
      @property_hash[:utilization].each_pair do |k, v|
        utilization << "#{k}=#{v} "
      end
    end
    unless @property_hash[:metadata].empty?
      metadatas = 'meta '
      @property_hash[:metadata].each_pair do |k, v|
        metadatas << "#{k}=#{v} "
      end
    end
    updated = 'primitive '
    updated << "#{@property_hash[:name]} #{@property_hash[:primitive_class]}:"
    updated << "#{@property_hash[:provided_by]}:" if @property_hash[:provided_by]
    updated << "#{@property_hash[:primitive_type]} "
    updated << "#{operations} " unless operations.nil?
    updated << "#{parameters} " unless parameters.nil?
    updated << "#{utilization} " unless utilization.nil?
    updated << "#{metadatas} " unless metadatas.nil?
    debug("Loading update: #{updated}")
    Tempfile.open('puppet_crm_update') do |tmpfile|
      tmpfile.write(updated)
      tmpfile.flush
      cmd = ['crm', '-F', 'configure', 'load', 'update', tmpfile.path.to_s]
      self.class.run_command_in_cib(cmd, @resource[:cib])
    end
  end
end
