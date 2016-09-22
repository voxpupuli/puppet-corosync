begin
  require 'puppet_x/voxpupuli/corosync/provider/crmsh'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync
  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/crmsh'
end

Puppet::Type.type(:cs_location).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive locations on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.
  commands crm: 'crm'

  mk_resource_methods

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:crm), 'configure', 'show', 'xml']
    raw = Puppet::Util::Execution.execute(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_location') do |e|
      # The node2hash method maps resource locations from XML into hashes.
      # The expression key is handled differently because the result must not
      # contain the id of the XML node. The crm command can not set the
      # expression id so Puppet would try to update the rule at every run.
      id, items = PuppetX::Voxpupuli::Corosync::Provider::CibHelper.node2hash(e, ['expression']).first

      location_instance = {
        name:               id,
        ensure:             :present,
        primitive:          items['rsc'],
        node_name:          items['node'],
        score:              items['score'] || 'INFINITY',
        rules:              items['rule'],
        resource_discovery: items['resource-discovery'],
        provider:           name
      }
      instances << new(location_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take
  # care of actually doing the work.
  def create
    @property_hash = {
      name:               @resource[:name],
      ensure:             :present,
      primitive:          @resource[:primitive],
      node_name:          @resource[:node_name],
      score:              @resource[:score],
      rules:              @resource[:rules],
      resource_discovery: @resource[:resource_discovery]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing location')
    PuppetX::Voxpupuli::Corosync::Provider::Crmsh.run_command_in_cib(['crm', 'configure', 'delete', @resource[:name]], @resource[:cib])
    @property_hash.clear
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    return if @property_hash.empty?

    updated = "location #{@property_hash[:name]} #{@property_hash[:primitive]}"

    if feature?(:discovery)
      updated << " resource-discovery=#{@property_hash[:resource_discovery]}"
    end

    unless @property_hash[:node_name].nil?
      updated << " #{@property_hash[:score]}: #{@property_hash[:node_name]}"
    end

    unless @property_hash[:rules].nil?
      @property_hash[:rules].each do |rule_item|
        name = rule_item.keys.first
        rule = rule_item[name]

        score = rule['score-attribute'] || rule['score']

        boolean_op = rule['boolean-op'] || 'and'
        expression = self.class.rule_expression(name, rule['expression'], boolean_op)

        updated << " rule $id=\"#{name}\""
        updated << " $role=\"#{rule['role']}\"" unless rule['role'].nil?
        updated << " #{score}: #{expression.join(' ')}"
      end
    end

    debug("Loading update: #{updated}")
    Tempfile.open('puppet_crm_update') do |tmpfile|
      tmpfile.write(updated)
      tmpfile.flush
      PuppetX::Voxpupuli::Corosync::Provider::Crmsh.run_command_in_cib(['crm', 'configure', 'load', 'update', tmpfile.path.to_s], @resource[:cib])
    end
  end
end
