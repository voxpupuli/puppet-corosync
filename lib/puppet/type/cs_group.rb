module Puppet
  newtype(:cs_group) do
    @doc = "Type for manipulating Corosync/Pacemkaer group entries.
      Groups are a set or resources (primitives) that need to be
      grouped together.

      More information can be found at the following link:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/ch-advanced-resources.html#group-resources"

    ensurable

    newparam(:name) do
      desc "Name identifier of this group entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."
      isnamevar
    end

    newparam(:primitives) do
        desc "An array of primitives to have in this group.  Must be listed in the
          order that you wish them to start."

        validate do |value|
          raise Puppet::Error, "Puppet::Type::Cs_Group: primitives property must be an array." unless value.is_a? Array
        end

        defaultto Array.new
    end

  end
end
