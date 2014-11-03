module Puppet
  newtype(:cs_rsc_defaults) do
    @doc = "Type for manipulating corosync/pacemaker global defaults for
      resource options. The type is pretty simple interface for setting
      key/value pairs or removing them completely.  Removing them will result
      in them taking on their default value.

      More information on resource defaults can be found here:

      * http://clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/s-resource-defaults.html
      * http://clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/s-resource-options.html"

    ensurable

    newparam(:name) do
      desc "Name identifier of this property.  Simply the name of the resource
        option.  Happily most of these are unique."

      isnamevar
    end

    newproperty(:value) do
      desc "Value of the property.  It is expected that this will be a single
        value but we aren't validating string vs. integer vs. boolean because
        resource options can range the gambit."
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end
