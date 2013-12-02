module Puppet
  newtype(:cs_clone) do
    @doc = "Type for manipulating Corosync/Pacemkaer clone entries.  Clone
      is an advanced service type for services which need to be active on
      multiple nodes.

      More information can be found at the following link:

      * http://clusterlabs.org/doc/en-US/Pacemaker/1.0/html/Pacemaker_Explained/s-resource-clone.html"

    ensurable

    newparam(:name) do
      desc "Name identifier of this clone entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."
      isnamevar
    end

    newproperty(:primitive) do
      desc "Primitive to clone."
    end

    newproperty(:metadata) do
      desc "A hash of metadata for the clone.  A clone can have a set of
        metadata."

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
      @parameters[:primitive].should
    end

  end
end
