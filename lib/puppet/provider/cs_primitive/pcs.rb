require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_primitive).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no
        plan to abstract corosync/pacemaker vs. keepalived.  Primitives in
        Corosync are the thing we desire to monitor; websites, ipaddresses,
        databases, etc, etc.  Here we manage the creation and deletion of
        these primitives.  We will accept a hash for what Corosync calls
        operations and parameters.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  commands :pcs => 'pcs'

  mk_resource_methods

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  # given an XML element (a <primitive> from cibadmin), produce a hash suitible
  # for creating a new provider instance.
  def self.element_to_hash(e)
    hash = {
      :primitive_class          => e.attributes['class'],
      :primitive_type           => e.attributes['type'],
      :provided_by              => e.attributes['provider'],
      :name                     => e.attributes['id'].to_sym,
      :ensure                   => :present,
      :provider                 => name,
      :parameters               => nvpairs_to_hash(e.elements['instance_attributes']),
      :operations               => {},
      :utilization              => nvpairs_to_hash(e.elements['utilization']),
      :metadata                 => nvpairs_to_hash(e.elements['meta_attributes']),
      :ms_metadata              => {},
      :promotable               => :false,
      :existing_resource        => :true,
      :existing_primitive_class => e.attributes['class'],
      :existing_primitive_type  => e.attributes['type'],
      :existing_promotable      => :false,
      :existing_provided_by     => e.attributes['provider'],
      :existing_metadata        => nvpairs_to_hash(e.elements['meta_attributes']),
      :existing_ms_metadata     => {},
      :existing_operations      => {}
    }

    operations = e.elements['operations']
    unless operations.nil?
      operations.each_element do |o|
        valids = o.attributes.reject do |k, _v| k == 'id' end
        if !valids['role'].nil?
          name = valids['name']
          name << ':'
          name << valids['role']
        else
          name = valids['name']
        end
        hash[:operations][name] = {}
        valids.each do |k, v|
          hash[:operations][name][k] = v if k != 'name' && k != 'role'
        end
        hash[:existing_operations] = hash[:operations].dup
      end
    end
    if e.parent.name == 'master'
      hash[:promotable] = :true
      hash[:existing_promotable] = :true
      unless e.parent.elements['meta_attributes'].nil?
        e.parent.elements['meta_attributes'].each_element do |m|
          hash[:ms_metadata][m.attributes['name']] = m.attributes['value']
        end
        hash[:existing_ms_metadata] = hash[:ms_metadata].dup
      end
    end

    hash
  end

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    # rubocop:disable Lint/UselessAssignment
    raw, status = Puppet::Provider::Pacemaker.run_command_in_cib(cmd)
    # rubocop:enable Lint/UselessAssignment
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//primitive') do |e|
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
      :primitive_class   => @resource[:primitive_class],
      :provided_by       => @resource[:provided_by],
      :primitive_type    => @resource[:primitive_type],
      :promotable        => @resource[:promotable],
      :existing_resource => :false
    }
    @property_hash[:parameters] = @resource[:parameters] unless @resource[:parameters].nil?
    @property_hash[:operations] = @resource[:operations] unless @resource[:operations].nil?
    @property_hash[:utilization] = @resource[:utilization] unless @resource[:utilization].nil?
    @property_hash[:metadata] = @resource[:metadata] unless @resource[:metadata].nil?
    @property_hash[:ms_metadata] = @resource[:ms_metadata] unless @resource[:ms_metadata].nil?
    @property_hash[:existing_metadata] = {}
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing primitive')
    Puppet::Provider::Pacemaker.run_command_in_cib([command(:pcs), 'resource', 'delete', '--force', @resource[:name]], @resource[:cib])
    @property_hash.clear
  end

  def promotable=(should)
    case should
    when :true
      @property_hash[:promotable] = should
    when :false
      @property_hash[:promotable] = should
      pcs('resource', 'delete', "ms_#{@resource[:name]}")
    end
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    unless @property_hash.empty?
      # Required for tests
      @resource = {} if @resource.nil?
      # The ressource_type variable is used to check if one of the class,
      # provider or type has changed
      ressource_type = "#{@property_hash[:primitive_class]}:"
      if @property_hash[:provided_by]
        ressource_type << "#{@property_hash[:provided_by]}:"
      end
      ressource_type << (@property_hash[:primitive_type]).to_s

      unless @property_hash[:operations].empty?
        operations = []
        @property_hash[:operations].each do |o|
          op_name = o[0]
          operations << 'op'
          if op_name.include? ':'
            items = op_name.split(':')
            operations << items[0]
            operations << "role=#{items[1]}"
          else
            operations << op_name
          end
          o[1].each_pair do |k, v|
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
      unless @property_hash[:metadata].empty?
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

      # We destroy the ressource if it's type, class or provider has changed
      unless @property_hash[:existing_resource] == :false
        existing_ressource_type = "#{@property_hash[:existing_primitive_class]}:"
        existing_ressource_type << "#{@property_hash[:existing_provided_by]}:" if @property_hash[:existing_provided_by]
        existing_ressource_type << (@property_hash[:existing_primitive_type]).to_s
        if existing_ressource_type != ressource_type
          debug('Removing primitive')
          Puppet::Provider::Pacemaker.run_command_in_cib([command(:pcs), 'resource', 'unclone', (@property_hash[:name]).to_s], @resource[:cib], false)
          Puppet::Provider::Pacemaker.run_command_in_cib([command(:pcs), 'resource', 'delete', '--force', (@property_hash[:name]).to_s], @resource[:cib])
          force_reinstall = :true
        end
      end

      if @property_hash[:existing_resource] == :false || force_reinstall == :true
        cmd = if Facter.value(:osfamily) == 'RedHat' && Facter.value(:operatingsystemmajrelease).to_s == '7'
                [command(:pcs), 'resource', 'create', '--force', '--no-default-ops', (@property_hash[:name]).to_s]
              else
                cmd = [command(:pcs), 'resource', 'create', '--force', (@property_hash[:name]).to_s]
              end
        cmd << ressource_type
        cmd += parameters unless parameters.nil?
        cmd += operations unless operations.nil?
        cmd += utilization unless utilization.nil?
        cmd += metadatas unless metadatas.nil?
        # rubocop:disable Lint/UselessAssignment
        raw, status = Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
        # rubocop:enable Lint/UselessAssignment
        # if we are using a master/slave resource, prepend ms_ before its name
        # and declare it as a master/slave resource
        if @property_hash[:promotable] == :true
          cmd = [command(:pcs), 'resource', 'master', "ms_#{@property_hash[:name]}", (@property_hash[:name]).to_s]
          # rubocop:disable Metrics/BlockNesting
          unless @property_hash[:ms_metadata].empty?
            # rubocop:enable Metrics/BlockNesting
            cmd << 'meta'
            @property_hash[:ms_metadata].each_pair do |k, v|
              cmd << "#{k}=#{v}"
            end
          end
          # rubocop:disable Lint/UselessAssignment
          raw, status = Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
          # rubocop:enable Lint/UselessAssignment
        end
        # try to remove the default monitor operation
        if @property_hash[:operations]['monitor'].nil?
          cmd = [command(:pcs), 'resource', 'op', 'remove', (@property_hash[:name]).to_s, 'monitor', 'interval=60s']
          Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib], false)
        end
      else
        if @property_hash[:promotable] == :false && @property_hash[:existing_promotable] == :true
          Puppet::Provider::Pacemaker.run_command_in_cib([command(:pcs), 'resource', 'delete', '--force', "ms_#{@property_hash[:name]}"], @resource[:cib])
        end
        @property_hash[:existing_operations].reject { |op, params| @property_hash[:operations].key?(op) && @property_hash[:operations][op] == params }.each do |o|
          cmd = [command(:pcs), 'resource', 'op', 'remove', (@property_hash[:name]).to_s]
          cmd << (o[0]).to_s
          o[1].each_pair do |k, v|
            cmd << "#{k}=#{v}"
          end
          Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
        end
        cmd = [command(:pcs), 'resource', 'update', (@property_hash[:name]).to_s]
        cmd += parameters unless parameters.nil?
        cmd += operations unless operations.nil?
        cmd += utilization unless utilization.nil?
        cmd += metadatas unless metadatas.nil?
        # rubocop:disable Lint/UselessAssignment
        raw, status = Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
        # rubocop:enable Lint/UselessAssignment
        if @property_hash[:promotable] == :true
          cmd = [command(:pcs), 'resource', 'update', "ms_#{@property_hash[:name]}", (@property_hash[:name]).to_s]
          # rubocop:disable Metrics/BlockNesting
          unless @property_hash[:ms_metadata].empty?
            # rubocop:enable Metrics/BlockNesting
            cmd << 'meta'
            @property_hash[:ms_metadata].each_pair do |k, v|
              cmd << "#{k}=#{v}"
            end
            @property_hash[:existing_ms_metadata].keys.reject { |key| @property_hash[:ms_metadata].key?(key) }.each do |k|
              cmd << "#{k}="
            end
          end
          # rubocop:disable Lint/UselessAssignment
          raw, status = Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
          # rubocop:enable Lint/UselessAssignment
        end
      end
    end
  end
end
