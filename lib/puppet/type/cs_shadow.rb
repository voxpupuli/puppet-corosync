module Puppet
  newtype(:cs_shadow) do
    @doc = "cs_shadow resources represent a Corosync shadow CIB. Any corosync
      resources defined with 'cib' set to the title of a cs_shadow resource
      will not become active until all other resources with the same cib
      value have also been applied."

    newparam(:name) do
      desc "Name of the shadow CIB to create and manage"
      isnamevar
    end

    feature :refreshable, "Refreshing Cs_shadow causes CIB to be applied.", :methods => [:refresh]
    def refresh
        provider.refresh
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end
