require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_location).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive locations on the system; add, delete, or adjust various
        aspects.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  commands :pcs      => 'pcs'
  commands :cibadmin => 'cibadmin'

  def self.element_to_hash(e)
    hash = {
      :name          => e.attributes['id'],
      :ensure        => :present,
      :primitive     => e.attributes['rsc'],
      :rule          => [],
      :provider      => self.name,
      :existing_rule => [],
    }

    if ! e.attributes['node'].nil?
      hash[:node_name] = e.attributes['node']
      hash[:score] = e.attributes['score']
    end

    if ! e.elements['rule'].nil?
      hash[:boolean] = e.elements['rule'].attributes['boolean-op']
      hash[:score] = e.elements['rule'].attributes['score']

      e.elements['rule'].each_element do |o|
        valids = o.attributes.reject do |k,v| k == 'id' end
        if ! valids['attribute'].nil?
          name = valids['attribute']
        end
        expression_hash = {}
        valids.each do |k,v|
          expression_hash[k] = v
        end
        hash[:rule].push(expression_hash)
      end
    end
    hash[:existing_rule] = hash[:rule].dup
    hash
  end

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_location') do |e|
      instances << new(element_to_hash(e))
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
      :score      => @resource[:score],
      :cib        => @resource[:cib]
    }
    @property_hash[:node_name] = @resource[:node_name] if ! @resource[:node_name].nil?
    @property_hash[:boolean] = @resource[:boolean] if ! @resource[:boolean].nil?
    @property_hash[:rule] = @resource[:rule] if ! @resource[:rule].nil?
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing location')
    cmd = [ command(:pcs), 'constraint', 'remove', @resource[:name] ]
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

  def boolean
    @property_hash[:boolean]
  end

  def rule
    @property_hash[:rule]
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

  def boolean=(should)
    @property_hash[:boolean] = should
  end

  def rule=(should)
    @property_hash[:rule] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the location_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    unless @property_hash.empty?

      doc = REXML::Document.new

      # add a new rsc_location XML element for a node-based constraint 
      if @property_hash[:node_name]
        rsc_location = doc.add_element 'rsc_location', {
          'id'    => "#{@property_hash[:name]}",
          'node'  => "#{@property_hash[:node_name]}",
          'rsc'   => "#{@property_hash[:primitive]}",
          'score' => "#{@property_hash[:score]}",
        }
        cmd_action = [ '--modify', '--allow-create', ]
      end

      # add a new rsc_location XML element for a rule-based constraint 
      unless @property_hash[:rule].empty?
        rsc_location = doc.add_element 'rsc_location', {
          'id'  => "#{@property_hash[:name]}",
          'rsc' => "#{@property_hash[:primitive]}",
        }

        # if there are more than 1 expressions defined in the array
        # a boolean attribute is required in the rule element.
        # 'and' is specified if no boolean parameter is present in the 
        # property_hash
        if @property_hash[:rule].length > 1
          if @property_hash[:boolean].nil?
            boolean = 'and'
          else
            boolean = @property_hash[:boolean]
          end
          rsc_location.add_element 'rule', {
            'boolean-op' => boolean,
            'id'         => "#{@property_hash[:name]}-rule",
            'score'      => "#{@property_hash[:score]}",
          }
        else
          rsc_location.add_element 'rule', {
            'id'    => "#{@property_hash[:name]}-rule",
            'score' => "#{@property_hash[:score]}",
          }
        end

        # Add each expression hash to the  expression XML element in order.
        @property_hash[:rule].each_with_index { |expression, index|
          expression['id'] = "#{@property_hash[:name]}-rule-expr-#{index+1}"
          rsc_location.elements['rule'].add_element 'expression', expression
        }

        # if you remove an expression from the cib, the replace switch is required,
        # as the expression you want to get rid of will be ignored when using the modify switch
        if (@property_hash[:existing_rule] and @property_hash[:rule].length < @property_hash[:existing_rule].length)
          cmd_action = '--replace'
        else
          cmd_action = [ '--modify', '--allow-create', ]
        end
      end

      # create / modify rsc_location elements using cibadmin.
      cmd = [ command(:cibadmin), cmd_action, '--scope=constraints', '--xml-text', "#{doc}" ]

      Puppet::Provider::Pacemaker::run_pcs_command(cmd)

    end
  end
end
