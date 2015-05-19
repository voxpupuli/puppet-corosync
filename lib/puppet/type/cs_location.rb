module Puppet
  newtype(:cs_location) do
    @doc = "Type for manipulating corosync/pacemaker resource location.
      More information on Corosync/Pacemaker colocation can be found here:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html
      * http://clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/ch08.html"

    ensurable

    newparam(:name) do
      desc "Identifier of the location entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end

    newproperty(:primitive) do
      desc "The corosync resource primitive to have a location applied.  "
    end

    newproperty(:node_name) do
      desc "The corosync node_name where the resource should be located.  "
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

    newproperty(:score) do
      desc "The priority of this location.  Primitives can be a part of
        multiple location groups and so there is a way to control which
        primitives get priority when forcing the move of other primitives.
        This value can be an integer but is often defined as the string
        INFINITY."

        defaultto 'INFINITY'
    end

    newproperty(:boolean) do
      desc "This allows you to define multiple rules in an expression.
        You may want to move a collection of resources away from a node
        if the ping resource agent score is below a threshold OR the ping
        resource isn't even defined."

    end

    newproperty(:rule, :array_matching => :all) do
      desc "An array of hashes for the rule expression. The expression is used
        to determine a suitablity of a node to run a collection of resources. This 
        is used in conjunction with the boolean property if you define more than one
        object in the expression."

      defaultto Array.new
    end


    autorequire(:cs_shadow) do
      [ @parameters[:cib] ]
    end

    autorequire(:service) do
      [ 'corosync' ]
    end

    validate do
      if [
        self[:node_name],
        self[:rule],
      ].compact.length > 1
        fail('Location constraints dictate that node_name and rule cannot co-exist for this type.') unless self[:rule].empty?
      end

    end
  end
end
