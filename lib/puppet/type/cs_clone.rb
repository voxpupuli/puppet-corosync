module Puppet
  newtype(:cs_clone) do
    @doc = "Type for manipulating Corosync/Pacemaker clone resources.
      Clones are required when you have a resource that can run in more
      than one place simultaneously, e.g. an active/active pair.
      
      More information can be found here:
      http://clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/s-resource-clone.html
      
      In order to declare a clone resource, you must already have a cs_primitive
      resource to clone."

    ensurable

    newparam(:name) do
      desc "Name identifier of this clone resource. This value needs to be unique
        across the entire Corosync/Pacemaker configuration, since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end

    newproperty(:primitive) do
      desc "The primitive to clone."
    end

    newproperty(:metadata) do
      # This would be much better expressed as multiple properties.
      #
      desc "A hash of metadata for the clone resource. This is effectively the resource's
        configuration. Hash keys that you can use here are: clone-max, clone-node-max,
        notify, globally-unique, ordered, interleave.

        The options priority, target-role, and is-managed are inherited from the primitive.

        For more detail, see: http://clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/_clone_options.html"

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Clone: metadata property must be a hash." unless value.is_a? Hash
      end

      defaultto Hash.new
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

    autorequire(:cs_shadow) do
      [ @parameters[:cib] ]
    end

    autorequire(:service) do
      [ 'corosync' ]
    end

    autorequire(:cs_primitive) do
      [ @parameters[:primitive] ]
    end

  end
end

