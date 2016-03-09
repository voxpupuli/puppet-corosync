require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_location).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive locations on the system; add, delete, or adjust various
        aspects.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  commands :pcs => 'pcs'

  mk_resource_methods

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = Puppet::Provider::Pacemaker.run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    constraints = doc.root.elements['configuration'].elements['constraints']
    unless constraints.nil?
      constraints.each_element('rsc_location') do |e|
        items = e.attributes

        location_instance = {
          :name               => items['id'],
          :ensure             => :present,
          :primitive          => items['rsc'],
          :node_name          => items['node'],
          :score              => items['score'],
          :resource_discovery => items['resource-discovery'],
          :provider           => name
        }
        instances << new(location_instance)
      end
    end
    instances
  end

  # Create just adds our resource to the location_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name               => @resource[:name],
      :ensure             => :present,
      :primitive          => @resource[:primitive],
      :node_name          => @resource[:node_name],
      :score              => @resource[:score],
      :resource_discovery => @resource[:resource_discovery]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing location')
    cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
    Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
    @property_hash.clear
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the location_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    unless @property_hash.empty?
      # Remove existing location
      cmd = ['pcs', 'constraint', 'resource', 'remove', @resource[:name]]
      Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib], false)
      cmd = ['pcs', 'constraint', 'location', 'add', @property_hash[:name], @property_hash[:primitive], @property_hash[:node_name], @property_hash[:score]]
      cmd << "resource-discovery=#{@property_hash[:resource_discovery]}" unless @property_hash[:resource_discovery].nil?
      Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
    end
  end
end
