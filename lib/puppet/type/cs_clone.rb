# frozen_string_literal: true

Puppet::Type.newtype(:cs_clone) do
  @doc = "Type for manipulating corosync/pacemaker resource clone.
    More information on Corosync/Pacemaker colocation can be found here:

    * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html"

  ensurable

  newparam(:name) do
    desc "Identifier of the clone entry. This value needs to be unique
      across the entire Corosync/Pacemaker configuration since it doesn't have
      the concept of name spaces per type."

    isnamevar
  end

  newproperty(:primitive) do
    desc 'The corosync resource primitive to be cloned.'
  end

  newproperty(:group) do
    desc 'The corosync resource group to be cloned.'
  end

  newproperty(:clone_max) do
    desc "How many copies of the resource to start.
      Defaults to the number of nodes in the cluster."

    newvalues(%r{\d+}, :absent)

    defaultto :absent
  end
  newproperty(:clone_node_max) do
    desc "How many copies of the resource can be started on a single node.
    Defaults to 1."

    newvalues(%r{\d+}, :absent)

    defaultto :absent
  end

  newproperty(:notify_clones) do
    desc "When stopping or starting a copy of the clone, tell all the other copies beforehand
      and when the action was successful.
      Allowed values: true, false"

    newvalues(:true, :false, :absent)

    defaultto :absent
  end

  newproperty(:globally_unique) do
    desc "Does each copy of the clone perform a different function?
      Allowed values: true, false"

    newvalues(:true, :false, :absent)

    defaultto :absent
  end

  newproperty(:ordered) do
    desc 'Should the copies be started in series (instead of in parallel). Allowed values: true, false'

    newvalues(:true, :false, :absent)

    defaultto :absent
  end

  newproperty(:interleave) do
    desc "Changes the behavior of ordering constraints (between clones/masters) so that instances can start/stop
      as soon as their peer instance has (rather than waiting for every instance of the other clone has).
      Allowed values: true, false"

    newvalues(:true, :false, :absent)

    defaultto :absent
  end

  newproperty(:promotable) do
    desc 'If true, clone instances can perform a special role that Pacemaker will manage via the resource agent’s
      promote and demote actions. The resource agent must support these actions. Allowed values: false, true'

    newvalues(:true, :false, :absent)

    defaultto :absent
  end

  newproperty(:promoted_max) do
    desc 'If promotable is true, the number of instances that can be promoted at one time across the entire cluster'

    newvalues(%r{\d+}, :absent)

    defaultto :absent
  end

  newproperty(:promoted_node_max) do
    desc 'If promotable is true and globally-unique is false, the number of clone instances can be promoted at one time on a single node'

    newvalues(%r{\d+}, :absent)

    defaultto :absent
  end

  newparam(:cib) do
    desc "Corosync applies its configuration immediately. Using a CIB allows
      you to group multiple primitives and relationships to be applied at
      once. This can be necessary to insert complex configurations into
      Corosync correctly.

      This parameter sets the CIB this colocation should be created in. A
      cs_shadow resource with a title of the same name as this value should
      also be added to your manifest."
  end

  autorequire(:service) do
    %w[corosync pacemaker]
  end

  autorequire(:cs_shadow) do
    autos = []
    autos << @parameters[:cib].value if @parameters[:cib]
    autos
  end

  { cs_group: :group, cs_primitive: :primitive }.each do |type, property|
    autorequire(type) do
      autos = []
      autos << unmunge_cs_primitive(should(property)) if should(property)

      autos
    end
  end

  def unmunge_cs_primitive(name)
    name = name.split(':')[0]
    name = name[3..] if name.start_with? 'ms_'

    name
  end

  validate do
    return if self[:ensure] == :absent

    mandatory_single_properties = %i[primitive group]
    has_should = mandatory_single_properties.select { |prop| should(prop) }
    raise Puppet::Error, "You cannot specify #{has_should.join(' and ')} on this type (only one)" if has_should.length > 1
    raise Puppet::Error, "You must specify #{mandatory_single_properties.join(' or ')}" if has_should.length != 1
  end
end
