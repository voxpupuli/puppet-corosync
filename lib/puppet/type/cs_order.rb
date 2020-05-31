require 'puppet/property/boolean'

Puppet::Type.newtype(:cs_order) do
  @doc = "Type for manipulating Corosync/Pacemkaer ordering entries.  Order
    entries are another type of constraint that can be put on sets of
    primitives but unlike colocation, order does matter.  These designate
    the order at which you need specific primitives to come into a desired
    state before starting up a related primitive.

    More information can be found at the following link:

    * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_controlling_resource_start_stop_ordering.html"

  ensurable

  feature :kindness, 'Support for the kind parameter'

  newparam(:name) do
    desc "Name identifier of this ordering entry.  This value needs to be unique
      across the entire Corosync/Pacemaker configuration since it doesn't have
      the concept of name spaces per type."
    isnamevar
  end

  newproperty(:first) do
    desc "First Corosync primitive.  Just like colocation, our primitives for
      ording come in pairs but this time order matters so we need to define
      which primitive starts the desired state change chain."

    munge do |value|
      value = "#{value}:start" unless value.include?(':')
      value
    end
  end

  newproperty(:second) do
    desc "Second Corosync primitive.  Our second primitive will move to the
      desired state after the first primitive."

    munge do |value|
      value = "#{value}:start" unless value.include?(':')
      value
    end
  end

  newparam(:cib) do
    desc "Corosync applies its configuration immediately. Using a CIB allows
      you to group multiple primitives and relationships to be applied at
      once. This can be necessary to insert complex configurations into
      Corosync correctly.

      This paramater sets the CIB this order should be created in. A
      cs_shadow resource with a title of the same name as this value should
      also be added to your manifest."
  end

  newproperty(:kind, required_features: :kindness) do
    desc "How to enforce the constraint.

    Allowed values:
    - Optional: Just a suggestion. Only applies if both resources are executing
    the specified actions. Any change in state by the first resource will have
    no effect on the then resource.
    - Mandatory: Always. If first does not perform first-action, then will not
    be allowed to performed then-action. If first is restarted, then
    (if running) will be stopped beforehand and started afterward.
    - Serialize: Ensure that no two stop/start actions occur concurrently for
    the resources. First and then can start in either order, but one must
    complete starting before the other can be started. A typical use case is
    when resource start-up puts a high load on the host."

    defaultto 'Mandatory'
  end

  newproperty(:symmetrical, boolean: true, parent: Puppet::Property::Boolean) do
    desc "Boolean specifying if the resources should stop in reverse order.
        Default value: true."
    defaultto true
  end

  autorequire(:service) do
    %w[corosync pacemaker]
  end

  [:cs_clone, :cs_group, :cs_primitive].each do |resource_type|
    autorequire(resource_type) do
      autos = []
      autos << unmunge_cs_resourcename(should(:first))
      autos << unmunge_cs_resourcename(should(:second))
      autos
    end
  end

  autorequire(:cs_shadow) do
    autos = []
    autos << @parameters[:cib].value if @parameters[:cib]
    autos
  end

  def unmunge_cs_resourcename(name)
    return if name.nil?
    name = name.split(':')[0]
    name = name[3..-1] if name.start_with? 'ms_'

    name
  end
end
