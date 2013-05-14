module Puppet
  newtype(:cs_location) do
    @doc = "Type for manipulating corosync/pacemaker location.  Location
      specified the preferred node of a primitive so that they travel
      to a node by its name or a set of rules.

      More information on Corosync/Pacemaker colocation can be found here:

      * http://clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_specifying_a_preferred_location.html"

    ensurable

    newparam(:name) do
      desc "Identifier of the location entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end

    newproperty(:rsc) do
      desc "One Corosync primitive to be located to a preferred node."
    end

    newparam(:cib) do
      desc "Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this colocation should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest."
    end

    newproperty(:host) do
      desc "The node of the preferred location."
    end

    newproperty(:rules, :array_matching => :all) do
      desc "Identifier of the colocation entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."
    end

    newproperty(:score) do
      desc "The priority of this location."
    end

    autorequire(:cs_shadow) do
      [ @parameters[:cib] ]
    end

    autorequire(:service) do
      [ 'corosync' ]
    end

    autorequire(:cs_primitive) do
      @parameters[:rsc]
    end
 
  end
end
