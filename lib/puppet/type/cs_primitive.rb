module Puppet
  newtype(:cs_primitive) do
    @doc = "Type for manipulating Corosync/Pacemkaer primitives.  Primtives
      are probably the most important building block when creating highly
      available clusters using Corosync and Pacemaker.  Each primitive defines
      an application, ip address, or similar to monitor and maintain.  These
      managed primitves are maintained using what is called a resource agent.
      These resource agents have a concept of class, type, and subsystem that
      provides the functionality.  Regretibly these pieces of vocabulary
      clash with those used in Puppet so to overcome the name clashing the
      property and parameter names have been qualified a bit for clarity.

      More information on primitive definitions can be found at the following
      link:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_adding_a_resource.html"

    ensurable

    newparam(:name) do
      desc "Name identifier of primitive.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end

    newparam(:primitive_class) do
      desc "Corosync class of the primitive.  Examples of classes are lsb or ocf.
        Lsb funtiony a lot like the init provider in Puppet for services, an init
        is ran periodically on each host to identify status, or star and stop a
        particular application.  Ocf of the other hand is a script with
        meta-data  and stucture that is specific to Corosync and Pacemaker."
    end

    newparam(:primitive_type) do
      desc "Corosync primitive type.  Type generally matches to the specific
        'thing' your managing, i.e. ip address or vhost.  Though, they can be
        completely arbitarily named and manage any number of underlying
        applications or resources."
    end

    newparam(:provided_by) do
      desc "Corosync primitive provider.  All resource agents used in a primitve
        have a something that provides them to the system, be it the Pacemaker
        or redhat plugins...there not always obvious though and currently this
        leaves it up to you to understand Corosync enough to figure it out.
        Usually, if it isn't obvious it is because there only one provider for
        a resource agent.

        To find the list of providers for a resource agent run the following
        from the command line has Corosync installed:

        * `crm configure ra providers <ra> <class>`"
    end

    # Our parameters and operations properties must be hashes.
    newproperty(:parameters) do
      desc "A hash of params for the primitive.  Parameters in a primitive are
        used by the underlying resource agent, each class using them slightly
        differently.  In ocf scripts they are exported and pulled into the
        script as variables to be used.  Since the list of these parameters
        are completely arbitrary and validity not enforced we simply defer
        defining a model and just accept a hash."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: parameters property must be a hash." unless value.is_a? Hash
      end

      defaultto Hash.new
    end

    newproperty(:operations) do
      desc "A hash of operations for the primitive.  Operations defined in a
        primitive are little more predictable as they are commonly things like
        monitor or start and their values are in seconds.  Since each resource
        agent can define its own set of operations we are going to defer again
        and just accept a hash.  There maybe room to model this one but it
        would require a review of all resource agents to see if each operation
        is valid."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: operations property must be a hash." unless value.is_a? Hash
      end

      defaultto Hash.new
    end

    newproperty(:metadata) do
      desc "A hash of metadata for the primitive.  A primitive can have a set of
        metadata that doesn't affect the underlying Corosync type/provider but
        affect that concept of a resource.  This metadata is similar to Puppet's
        resources resource and some meta-parameters, they change resource
        behavior but have no affect of the data that is synced or manipulated."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: metadata property must be a hash." unless value.is_a? Hash
      end

      defaultto Hash.new
    end

    newproperty(:ms_metadata) do
      desc "A hash of metadata for the master/slave primitive state."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: ms_metadata property must be a hash" unless value.is_a? Hash
      end

      defaultto Hash.new
    end

    newproperty(:promotable) do
      desc "Designates if the primitive is capable of being managed in a master/slave
        state.  This will create a new ms resource in your Corosync config and add
        this primitive to it.  Concequently Corosync will be helpful and update all
        your colocation and order resources too but Puppet won't.  At this time you
        will need to compensate for this and make sure your colocation and order
        resources have been updated by replacing the name of this primitive with
        ms_$name.  I am currently unsure on how to obtain this data directly from
        Corosync.  Once it updates them is doesn't seem to leave anything indicating
        why in the dump of the config."

        newvalues(:true, :false)

        defaultto :false
    end
  end
end

