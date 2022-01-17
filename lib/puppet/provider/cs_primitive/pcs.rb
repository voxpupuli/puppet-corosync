# frozen_string_literal: true

begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_primitive).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  desc 'Specific provider for a rather specific type since I currently have no
        plan to abstract corosync/pacemaker vs. keepalived.  Primitives in
        Corosync are the thing we desire to monitor; websites, ipaddresses,
        databases, etc, etc.  Here we manage the creation and deletion of
        these primitives.  We will accept a hash for what Corosync calls
        operations and parameters.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  commands pcs: 'pcs'

  mk_resource_methods

  defaultfor operatingsystem: %i[fedora centos redhat]

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
      existing_resource: :true,
      existing_primitive_class: e.attributes['class'],
      existing_primitive_type: e.attributes['type'],
      existing_provided_by: e.attributes['provider'],
      existing_metadata: nvpairs_to_hash(e.elements['meta_attributes']),
      existing_operations: []
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
        hash[:existing_operations] << operation
      end

    hash
  end

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//primitive') do |e|
      instances << new(element_to_hash(e))
    end
    instances
  end

  # Returns the appropriate sub-command based on the primitive class type.
  # Currently only stonith and resource are valid options.
  def self._determine_primitive_subcommand(primitive_class)
    if primitive_class.to_s == 'stonith'
      'stonith'
    else
      'resource'
    end
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  # The existing_resource is there because pcs does not have a single command that
  # updates or create a resource, so we flag the resources with that parameter
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      primitive_class: @resource[:primitive_class],
      provided_by: @resource[:provided_by],
      primitive_type: @resource[:primitive_type],
      existing_resource: :false
    }
    @property_hash[:parameters] = @resource[:parameters] unless @resource[:parameters].nil?
    @property_hash[:operations] = @resource[:operations] unless @resource[:operations].nil?
    @property_hash[:utilization] = @resource[:utilization] unless @resource[:utilization].nil?
    @property_hash[:metadata] = @resource[:metadata] unless @resource[:metadata].nil?
    @property_hash[:existing_metadata] = {}
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    pcs_subcommand = self.class._determine_primitive_subcommand(@property_hash[:primitive_class])
    debug("Removing primitive - #{pcs_subcommand}")
    self.class.run_command_in_cib([command(:pcs), pcs_subcommand, 'delete', '--force', @resource[:name]], @resource[:cib])
    @property_hash.clear
  end

  # Performs a subset of flush operations which are relevant only to stonith
  # resources. Non stonith resources will never call this method.
  #
  # Several major differences exist between this function and standard resource
  # handling
  # * Only the primitive type is used to determine the resource type
  # * The update command can only modify stonith device options. Metadata, and
  # operation changes require removal and recreation
  def _flush_stonith(operations, parameters, metadatas)
    pcs_subcommand = self.class._determine_primitive_subcommand(@property_hash[:primitive_class])

    resource_type = (@property_hash[:primitive_type]).to_s

    # We destroy the resource if it's type, operations, or metadata has changed
    if @property_hash[:existing_resource] == :true
      existing_resource_type = (@property_hash[:existing_primitive_type]).to_s
      meta = @property_hash[:metadata]
      e_meta = @property_hash[:existing_metadata]
      ops = @property_hash[:operations]
      e_ops = @property_hash[:existing_operations]

      # Test whether we need to force reinstall
      force_reinstall = if existing_resource_type != resource_type
                          :true
                        elsif !((e_ops - ops) + (ops - e_ops)).empty?
                          :true
                        elsif meta != e_meta
                          :true
                        else
                          :false
                        end

      if force_reinstall == :true
        debug('Removing stonith')
        self.class.run_command_in_cib([command(:pcs), pcs_subcommand, 'delete', '--force', (@property_hash[:name]).to_s], @resource[:cib])
      end
    end

    if @property_hash[:existing_resource] == :false || force_reinstall == :true
      cmd = [command(:pcs), pcs_subcommand, 'create', '--force', (@property_hash[:name]).to_s]
      cmd << resource_type
      cmd += parameters unless parameters.nil?
      cmd += operations unless operations.nil?
      cmd += metadatas unless metadatas.nil?
      self.class.run_command_in_cib(cmd, @resource[:cib])
    else
      cmd = [command(:pcs), pcs_subcommand, 'update', (@property_hash[:name]).to_s]
      # Only update if parameters are present
      unless parameters.nil?
        cmd += parameters
        self.class.run_command_in_cib(cmd, @resource[:cib])
      end
    end
  end

  # Performs the relevant flush operations for standard resource primitives
  def _flush_resource(operations, parameters, utilization, metadatas)
    pcs_subcommand = self.class._determine_primitive_subcommand(@property_hash[:primitive_class])

    # The resource_type variable is used to check if one of the class,
    # provider or type has changed. Since stonith resources have a special
    # command they do not include a provider or class in their type name
    resource_type = "#{@property_hash[:primitive_class]}:"
    resource_type << "#{@property_hash[:provided_by]}:" if @property_hash[:provided_by]
    resource_type << (@property_hash[:primitive_type]).to_s

    # We destroy the resource if it's type, class or provider has changed
    unless @property_hash[:existing_resource] == :false
      existing_resource_type = "#{@property_hash[:existing_primitive_class]}:"
      existing_resource_type << "#{@property_hash[:existing_provided_by]}:" if @property_hash[:existing_provided_by]
      existing_resource_type << (@property_hash[:existing_primitive_type]).to_s

      if existing_resource_type != resource_type
        debug('Removing primitive')
        self.class.run_command_in_cib([command(:pcs), pcs_subcommand, 'unclone', (@property_hash[:name]).to_s], @resource[:cib], false)
        self.class.run_command_in_cib([command(:pcs), pcs_subcommand, 'delete', '--force', (@property_hash[:name]).to_s], @resource[:cib])
        force_reinstall = :true
      end
    end

    if @property_hash[:existing_resource] == :false || force_reinstall == :true
      cmd = [command(:pcs), pcs_subcommand, 'create', '--force', '--no-default-ops', (@property_hash[:name]).to_s]
      cmd << resource_type
      cmd += parameters unless parameters.nil?
      cmd += operations unless operations.nil?
      cmd += utilization unless utilization.nil?
      cmd += metadatas unless metadatas.nil?
      # default_op = { 'monitor' => { 'interval' => '60s' } }
      # unless @property_hash[:operations].include?(default_op)
      #   cmd = [command(:pcs), pcs_subcommand, 'op', 'remove', (@property_hash[:name]).to_s, 'monitor', 'interval=60s']
      # end
      self.class.run_command_in_cib(cmd, @resource[:cib], false)
    else
      @property_hash[:existing_operations].reject { |op| @property_hash[:operations].include?(op) }.each do |o|
        cmd = [command(:pcs), pcs_subcommand, 'op', 'remove', (@property_hash[:name]).to_s]
        cmd << o.keys.first.to_s
        o.values.first.each_pair do |k, v|
          cmd << "#{k}=#{v}"
        end
        self.class.run_command_in_cib(cmd, @resource[:cib])
      end
      cmd = [command(:pcs), pcs_subcommand, 'update', (@property_hash[:name]).to_s]
      cmd += parameters unless parameters.nil?
      cmd += operations unless operations.nil?
      cmd += utilization unless utilization.nil?
      cmd += metadatas unless metadatas.nil?
      self.class.run_command_in_cib(cmd, @resource[:cib])
    end
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    return if @property_hash.empty?

    # Required for tests
    @resource = {} if @resource.nil?

    # Construct the operation, utilization, and standard parameter structures
    unless @property_hash[:operations].empty?
      operations = []
      @property_hash[:operations].each do |o|
        # o is {k => v}
        op_name = o.keys.first.to_s
        operations << 'op'
        operations << op_name
        o.values.first.each_pair do |k, v|
          operations << "#{k}=#{v}"
        end
      end
    end
    unless @property_hash[:parameters].empty?
      parameters = []
      @property_hash[:parameters].each_pair do |k, v|
        parameters << "#{k}=#{v}"
      end
    end
    unless @property_hash[:utilization].empty?
      utilization = ['utilization']
      @property_hash[:utilization].each_pair do |k, v|
        utilization << "#{k}=#{v}"
      end
    end

    # Clear all metadata structures when specified
    if @resource&.instance_of?(:cs_primitive) && @resource[:unmanaged_metadata]
      @resource[:unmanaged_metadata].each do |parameter_name|
        @property_hash[:metadata].delete(parameter_name)
        @property_hash[:existing_metadata]&.delete(parameter_name)
      end
    end

    unless @property_hash[:metadata].empty? && @property_hash[:existing_metadata].empty?
      metadatas = ['meta']
      @property_hash[:metadata].each_pair do |k, v|
        metadatas << "#{k}=#{v}"
      end
      unless @property_hash[:existing_metadata].empty?
        @property_hash[:existing_metadata].keys.reject { |key| @property_hash[:metadata].key?(key) }.each do |k|
          metadatas << "#{k}="
        end
      end
    end

    # Establish whether this is a regular resource or a special stonith resource
    # The destinction exists only because pcs uses a different subcommand to
    # interact with stonith resources
    is_stonith = (@property_hash[:primitive_class]).to_s == 'stonith'

    # Call the appropriate helper function to generate the PCS commands
    if is_stonith
      _flush_stonith(operations, parameters, metadatas)
    else
      _flush_resource(operations, parameters, utilization, metadatas)
    end
  end
end
