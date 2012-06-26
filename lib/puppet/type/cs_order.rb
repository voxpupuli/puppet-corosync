module Puppet
  newtype(:cs_order) do
    @doc = "Type for manipulating Corosync/Pacemkaer ordering entries.  Order
      entries are another type of constraint that can be put on sets of
      primitives but unlike colocation, order does matter.  These designate
      the order at which you need specific primitives to come into a desired
      state before starting up a related primitive.

      More information can be found at the following link:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_controlling_resource_start_stop_ordering.html"

    ensurable

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
    end

    newproperty(:second) do
      desc "Second Corosync primitive.  Our second primitive will move to the
        desired state after the first primitive."
    end

    newparam(:cib) do
      desc "The shadow CIB group that the order belongs to"
    end

    newproperty(:score) do
      desc "The priority of the this ordered grouping.  Primitives can be a part
        of multiple order groups and so there is a way to control which
        primitives get priority when forcing the order of state changes on
        other primitives.  This value can be an integer but is often defined
        as the string INFINITY."

      defaultto 'INFINITY'
    end
  end
end
