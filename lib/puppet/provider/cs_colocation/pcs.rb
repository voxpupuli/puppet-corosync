require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_colocation).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  commands :pcs => 'pcs'

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    # rubocop:disable Lint/UselessAssignment
    raw, status = run_pcs_command(cmd)
    # rubocop:enable Lint/UselessAssignment
    doc = REXML::Document.new(raw)
    resource_set_options = ['sequential', 'require-all', 'action', 'role']

    constraints = doc.root.elements['configuration'].elements['constraints']
    unless constraints.nil?
      constraints.each_element('rsc_colocation') do |e|
        items = e.attributes

        if e.has_elements?
          resource_sets = []
          e.each_element('resource_set') do |rs|
            resource_set = {}
            options = {}
            resource_set_options.each do |o|
              options[o] = rs.attributes[o] if rs.attributes[o]
            end
            # rubocop:disable Style/ZeroLengthPredicate
            resource_set['options'] = options if options.keys.size > 0
            # rubocop:enable Style/ZeroLengthPredicate
            resource_set['primitives'] = []
            rs.each_element('resource_ref') do |rr|
              resource_set['primitives'] << rr.attributes['id']
            end
            resource_sets << resource_set
          end
          colocation_instance = {
            :name       => items['id'],
            :ensure     => :present,
            :primitives => resource_sets,
            :score      => items['score'],
            :provider   => name,
            :new        => false
          }
        else
          rsc = if items['rsc-role'] && items['rsc-role'] != 'Started'
                  "#{items['rsc']}:#{items['rsc-role']}"
                else
                  items['rsc']
                end

          with_rsc = if items ['with-rsc-role'] && items['with-rsc-role'] != 'Started'
                       "#{items['with-rsc']}:#{items['with-rsc-role']}"
                     else
                       items['with-rsc']
                     end

          colocation_instance = {
            :name       => items['id'],
            :ensure     => :present,
            :primitives => [rsc, with_rsc],
            :score      => items['score'],
            :provider   => name,
            :new        => false
          }
        end
        instances << new(colocation_instance)
      end
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    # rubocop:disable Lint/UselessAssignment
    primitives = []
    # rubocop:enable Lint/UselessAssignment
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :primitives => @resource[:primitives],
      :score      => @resource[:score],
      :new        => true
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing colocation')
    cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
    Puppet::Provider::Pacemaker.run_pcs_command(cmd)
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitives
    @property_hash[:primitives]
  end

  # Getter that obtains the our score that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def score
    @property_hash[:score]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def primitives=(should)
    @property_hash[:primitives] = should
  end

  def score=(should)
    @property_hash[:score] = should
  end

  # Format a resource set for the pcs constraint colocation set
  def format_resource_set(rs)
    r = []
    if rs.is_a?(Hash)
      rs.each do |o, v|
        r << "#{o}=#{v}"
      end
    elsif rs.is_a?(Array)
      r << rs.shift until rs.empty?
    end
    r
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the pcs command.
  def flush
    unless @property_hash.empty?

      ENV['CIB_shadow'] = @property_hash[:cib]

      if @property_hash[:new] == false
        debug('Removing colocation')
        cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
        Puppet::Provider::Pacemaker.run_pcs_command(cmd, @resource[:cib])
      end
      first_item = @property_hash[:primitives].shift
      cmd = [command(:pcs), 'constraint', 'colocation']
      if first_item.is_a?(Array)
        cmd << 'set'
        cmd << format_resource_set(first_item)
        until @property_hash[:primitives].empty?
          cmd += format_resource_set(@property_hash[:primitives].shift)
        end
        cmd << 'setoptions'
        cmd << "id=#{@property_hash[:name]}"
        cmd << "score=#{@property_hash[:score]}"
      else
        cmd << 'add'
        rsc = first_item
        if rsc.include? ':'
          items = rsc.split(':')
          # rubocop:disable Metrics/BlockNesting
          if items[1] == 'Master'
            cmd << 'master'
          elsif items[1] == 'Slave'
            cmd << 'slave'
          end
          cmd << items[0]
        else
          cmd << rsc
        end
        cmd << 'with'
        rsc = @property_hash[:primitives].shift
        if rsc.include? ':'
          items = rsc.split(':')
          if items[1] == 'Master'
            cmd << 'master'
          elsif items[1] == 'Slave'
            cmd << 'slave'
          end
          cmd << items[0]
        else
          cmd << rsc
        end
        cmd << @property_hash[:score]
        cmd << "id=#{@property_hash[:name]}"
      end
      # rubocop:disable Lint/UselessAssignment
      raw, status = Puppet::Provider::Pacemaker.run_pcs_command(cmd, @resource[:cib])
      # rubocop:enable Lint/UselessAssignment
    end
  end
end
