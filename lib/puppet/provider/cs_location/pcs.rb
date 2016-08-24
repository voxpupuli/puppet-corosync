begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync
  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_location).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive locations on the system; add, delete, or adjust various
        aspects.'

  defaultfor operatingsystem: [:fedora, :centos, :redhat]
  has_feature :discovery

  commands pcs: 'pcs'

  mk_resource_methods

  # given an XML element containing some <expression>s, return a hash. Return an
  # empty hash if `e` is nil.
  def self.rules_to_hash(e)
    return {} if e.nil?

    hash = {}
    e.each_element do |i|
      hash[i.attributes['name']] = i.attributes['value']
    end

    hash
  end

  # given an XML element (a <rsc_location> from cibadmin), produce a hash
  # suitable for creating a new provider instance.
  def self.element_to_hash(e)
    hash = {
      name:      e.attributes['id'],
      ensure:    :present,
      primitive: e.attributes['rsc'],
      node_name: e.attributes['node'],
      score:     e.attributes['score'],
      rule:      rules_to_hash(e.elements['rule']),
      provider:  name
    }

    hash
  end

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    constraints = doc.root.elements['configuration'].elements['constraints']
    unless constraints.nil?
      constraints.each_element('rsc_location') do |e|
        items = e.attributes

        location_instance = {
          name:               items['id'],
          ensure:             :present,
          primitive:          items['rsc'],
          node_name:          items['node'],
          score:              items['score'],
          resource_discovery: items['resource-discovery'],
          rule:               items['rule'],
          provider:           name
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
      name:               @resource[:name],
      ensure:             :present,
      primitive:          @resource[:primitive],
      node_name:          @resource[:node_name],
      score:              @resource[:score],
      resource_discovery: @resource[:resource_discovery],
      rule:               @resource[:rule]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing location')
    cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
    PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd, @resource[:cib])
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
      PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd, @resource[:cib], false)
      cmd = ['pcs', 'constraint', 'location', 'add', @property_hash[:name], @property_hash[:primitive], @property_hash[:node_name], @property_hash[:score]]
      cmd << "resource-discovery=#{@property_hash[:resource_discovery]}" unless @property_hash[:resource_discovery].nil?
      PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd, @resource[:cib])

      unless @property_hash[:rule].nil?
        score_param = [] # default value: score=INFINITY
        rule_params = []
        @property_hash[:rule].each_pair do |k, v|
          if k == 'expression' # expression
            rule_params = [v['attribute'], v['operation'], v['value']]
          elsif k == 'score' || k == 'score-attribute' # score or score-attribute
            score_param = "#{k}=#{v}"
          end
        end
        cmd_rule = [command(:pcs), 'constraint', 'location', @property_hash[:primitive], 'rule', score_param, rule_params]
        PuppetX::Voxpupuli::Corosync::Provider::Pcs.run_command_in_cib(cmd_rule, @resource[:cib])
      end
    end
  end
end
