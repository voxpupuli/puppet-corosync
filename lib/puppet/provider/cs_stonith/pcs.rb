require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_stonith).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'A provider for creating fence devices to perform STONITH operations
	should the cluster find itself in trouble.
        Here we manage the creation and deletion of STONITH fence devices
        We will accept a hash for what Corosync calls
        operations and device_options.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  commands :pcs => 'pcs'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]
  # given an XML element containing some <nvpair>s, return a hash. Return an
  # empty hash if `e` is nil.
  def self.nvpairs_to_hash(e)
    return {} if e.nil?

    hash = {}
    e.each_element do |i|
      hash[(i.attributes['name'])] = i.attributes['value']
    end

    hash
  end

  # given an XML element (a <primitive> from cibadmin), produce a hash suitible
  # for creating a new provider instance.
  def self.element_to_hash(e)
    hash = {
      :fence_type               => e.attributes['type'],
      :name                     => e.attributes['id'].to_sym,
      :ensure                   => :present,
      :provider                 => self.name,
      :device_options           => nvpairs_to_hash(e.elements['instance_attributes']),
      :existing_resource        => :true,
      :existing_primitive_class => e.attributes['class'],
      :existing_fence_type      => e.attributes['type'],
      #:existing_operations      => {}
    }

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
    doc = REXML::Document.new(raw)

    # What does this mean? Is stonith correct?
    REXML::XPath.each(doc, '//stonith') do |e|
      instances << new(element_to_hash(e))
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  # The existing_resource is there because pcs does not have a single command that
  # updates or create a resource, so we flag the resources with that parameter
  def create
    @property_hash = {
      :name              => @resource[:name],
      :ensure            => :present,
      :fence_type        => @resource[:fence_type],
      :existing_resource => :false
    }
    @property_hash[:device_options] = @resource[:device_options] if ! @resource[:device_options].nil?
    @property_hash[:operations] = @resource[:operations] if ! @resource[:operations].nil?
    @property_hash[:utilization] = @resource[:utilization] if ! @resource[:utilization].nil?
    @property_hash[:metadata] = @resource[:metadata] if ! @resource[:metadata].nil?
    @property_hash[:ms_metadata] = @resource[:ms_metadata] if ! @resource[:ms_metadata].nil?
    @property_hash[:cib] = @resource[:cib] if ! @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing STONITH fence')
    Puppet::Provider::Pacemaker::run_pcs_command([command(:pcs), 'delete', @property_hash[:name]])
    @property_hash.clear
  end

  # Getters that obtains the device_options and operations defined in our primitive
  # that have been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def device_options
    @property_hash[:device_options]
  end

  def fence_type
    @property_hash[:fence_type]
  end

  # Our setters for device_options and operations.  Setters are used when the
  # resource already exists so we just update the current value in the
  # property_hash and doing this marks it to be flushed.
  def device_options=(should)
    @property_hash[:device_options] = should
  end

  def fence_type=(should)
    @property_hash[:fence_type] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    unless @property_hash.empty?
      # The resource_type variable is used to check if one of the class,
      # provider or type has changed
      resource_type = "#{@property_hash[:fence_type]}:"

      unless @property_hash[:device_options].empty?
        device_options = []
        @property_hash[:device_options].each_pair do |k,v|
          device_options << "#{k}=#{v}"
        end
      end

      # We destroy the ressource if it's type, class or provider has changed
      unless @property_hash[:existing_resource] == :false
        existing_resource_type = "#{@property_hash[:existing_fence_type]}:"
	# do I need a condition if no parameters are specified
        existing_resource_type << "#{@property_hash[:existing_fence_type]}"
        if existing_resource_type != resource_type
          debug('Removing fence device')
          Puppet::Provider::Pacemaker::run_pcs_command([command(:pcs), 'stonith', 'delete', @property_hash[:name]])
          force_reinstall = :true
        end
      end

      ENV['CIB_shadow'] = @property_hash[:cib]

      if @property_hash[:existing_resource] == :false or force_reinstall == :true
        cmd = [ command(:pcs), 'stonith', 'create', "#{@property_hash[:name]}" ]
        cmd << resource_type
        cmd += device_options unless device_options.nil?
        raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
      else
        cmd = [ command(:pcs), 'stonith', 'update', "#{@property_hash[:name]}" ]
        cmd += device_options unless device_options.nil?
        raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
      end
    end
  end
end
