require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_location).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive locations on the system; add, delete, or adjust various
        aspects.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  commands :pcs => 'pcs'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_location') do |e|
      items = e.attributes

      location_instance = {
        :name       => items['id'],
        :ensure     => :present,
        :primitive  => items['rsc'],
        :node_name  => items['node'],
        :score      => items['score'],
        :provider   => self.name
      }
      instances << new(location_instance)
    end
    instances
  end

  # Create just adds our resource to the location_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :primitive  => @resource[:primitive],
      :node_name  => @resource[:node_name],
      :score      => @resource[:score],
      :cib        => @resource[:cib]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing location')
    cmd = [ command(:pcs), 'constraint', 'resource', 'remove', @resource[:name] ]
    Puppet::Provider::Pacemaker::run_pcs_command(cmd)
    @property_hash.clear
  end

  # Getters that obtains the parameters defined in our location that have been
  # populated by prefetch or instances (depends on if your using puppet resource
  # or not).
  def primitive
    @property_hash[:primitive]
  end

  def node_name
    @property_hash[:node_name]
  end

  def score
    @property_hash[:score]
  end

  # Our setters for parameters.  Setters are used when the resource already
  # exists so we just update the current value in the location_hash and doing
  # this marks it to be flushed.
  def primitive=(should)
    @property_hash[:primitive] = should
  end

  def node_name=(should)
    @property_hash[:node_name] = should
  end

  def score=(should)
    @property_hash[:score] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the location_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    unless @property_hash.empty?
      cmd = [ command(:pcs), 'constraint', 'location', 'add', @property_hash[:name], @property_hash[:primitive], @property_hash[:node_name], @property_hash[:score]]
      Puppet::Provider::Pacemaker::run_pcs_command(cmd)
    end
  end
end
