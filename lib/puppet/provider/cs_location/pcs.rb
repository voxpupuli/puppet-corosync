# frozen_string_literal: true

begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_location).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive locations on the system; add, delete, or adjust various
        aspects.'

  defaultfor operatingsystem: %i[fedora centos redhat]
  has_feature :discovery

  commands pcs: 'pcs'

  mk_resource_methods

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    constraints = doc.root.elements['configuration'].elements['constraints']
    unless constraints.nil?
      constraints.each_element('rsc_location') do |e|
        # The node2hash method maps resource locations from XML into hashes.
        # The expression key is handled differently because the result must
        # not contain the id of the XML node. The crm command can not set the
        # expression id so Puppet would try to update the rule at every run.
        id, items = node2hash(e, ['expression']).first

        location_instance = {
          name: id,
          ensure: :present,
          primitive: items['rsc'],
          node_name: items['node'],
          score: items['score'] || 'INFINITY',
          rules: items['rule'],
          resource_discovery: items['resource-discovery'],
          provider: name
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
      name: @resource[:name],
      ensure: :present,
      primitive: @resource[:primitive],
      node_name: @resource[:node_name],
      score: @resource[:score],
      rules: @resource[:rules],
      resource_discovery: @resource[:resource_discovery]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing location')
    cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib])
    @property_hash.clear
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the location_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    return if @property_hash.empty?

    # Remove existing location
    cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib], false)
    unless @property_hash[:node_name].nil?
      cmd = [command(:pcs), 'constraint', 'location', 'add', '--force', @property_hash[:name], @property_hash[:primitive], @property_hash[:node_name], @property_hash[:score]]
      cmd << "resource-discovery=#{@property_hash[:resource_discovery]}" unless @property_hash[:resource_discovery].nil?
      self.class.run_command_in_cib(cmd, @resource[:cib])
    end

    return if @property_hash[:rules].nil?

    count = 0
    @property_hash[:rules].each do |rule_item|
      params = []
      name = rule_item.keys.first
      rule = rule_item[name]

      score = rule['score-attribute'].nil? ? "score=#{rule['score']}" : "score-attribute=\"#{rule['score-attribute']}\""

      boolean_op = rule['boolean-op'] || 'and'
      expression = self.class.rule_expression(name, rule['expression'], boolean_op)

      params << "id=#{name}"
      params << "constraint-id=#{@resource[:name]}" if count.zero?
      params << "role=#{rule['role']}" unless rule['role'].nil?
      params << score
      params += expression
      cmd_rule = if count.zero?
                   [command(:pcs), 'constraint', 'location', @resource[:primitive],
                    'rule'] + params
                 else
                   [command(:pcs), 'constraint', 'rule', 'add', @resource[:name]] + params
                 end
      self.class.run_command_in_cib(cmd_rule, @resource[:cib])
      count += 1
    end
  end
end
