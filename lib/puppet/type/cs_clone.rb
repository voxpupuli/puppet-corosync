module Puppet
  newtype(:cs_clone) do
    @doc = "Type for manipulating corosync/pacemaker resource clone.
      More information on Corosync/Pacemaker colocation can be found here:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html"

    ensurable

    newparam(:name) do
      desc "Identifier of the location entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end

    newproperty(:primitive) do
      desc "The corosync resource primitive to be cloned.  "
    end

    newproperty(:clone_max) do
      desc "How many copies of the resource to start.
        Defaults to the number of nodes in the cluster."
    end
    newproperty(:clone_node_max) do
      desc "How many copies of the resource can be started on a single node.
      Defaults to 1."
    end

    newproperty(:notify_clones) do
      desc "When stopping or starting a copy of the clone, tell all the other copies beforehand
        and when the action was successful.
        Allowed values: true, false"

        newvalues(:true, :false)
    end

    newproperty(:globally_unique) do
      desc "Does each copy of the clone perform a different function?
        Allowed values: true, false"

        newvalues(:true, :false)
    end

    newproperty(:ordered) do
      desc "Should the copies be started in series (instead of in parallel). Allowed values: true, false"

        newvalues(:true, :false)
    end

    newproperty(:interleave) do
      desc "Changes the behavior of ordering constraints (between clones/masters) so that instances can start/stop
        as soon as their peer instance has (rather than waiting for every instance of the other clone has).
        Allowed values: true, false"

        newvalues(:true, :false)
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

    autorequire(:cs_shadow) do
      [ @parameters[:cib] ]
    end

    autorequire(:service) do
      [ 'corosync' ]
    end

  end
end

