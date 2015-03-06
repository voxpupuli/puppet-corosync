module Puppet
  newtype(:cs_stonith) do
    @doc = "Type for manipulating Corosync/Pacemaker fence devices.
      More information on STONITH and fence devices can be found at the 
      following link:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_adding_a_resource.html"

    ensurable

    newparam(:name) do
      desc "Name identifier of the fence device.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end

    newparam(:fence_type) do
      desc "The fence decvice type to use. Examples are fence_ilo fence_ilo2 fence_apc"
    end

    # Our device_options properties must be a hash.
    newproperty(:device_options) do
      desc "A hash of fencing options for the fence device. Since the list of these 
        parameters are completely arbitrary and validity not enforced we simply defer
        defining a model and just accept a hash."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::cs_stonith: fence device options must be a hash." unless value.is_a? Hash
      end

      defaultto Hash.new
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end
