module Puppet
  newtype(:cs_clone) do

    ensurable

    newparam(:name) do
      desc "Fill this in "

      isnamevar
    end

    newproperty(:primitive) do
      desc "fill this in "
    end

    newproperty(:metadata) do 
      desc "A hash of metadata ... "

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

