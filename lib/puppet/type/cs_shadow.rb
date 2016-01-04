Puppet::Type.newtype(:cs_shadow) do
  @doc = "cs_shadow resources represent a Corosync shadow CIB. Any corosync
    resources defined with 'cib' set to the title of a cs_shadow resource
    will not become active until all other resources with the same cib
    value have also been applied."

  newparam(:cib) do
    isnamevar
  end

  newproperty(:epoch) do
    def sync
      provider.sync(@resource[:cib])
    end

    def retrieve
      provider.get_epoch(@resource[:cib])
    end

    def insync?(is)
      provider.insync?(@resource[:cib])
    end

    def change_to_s(currentvalue, newvalue)
      super(currentvalue, provider.get_epoch(@resource[:cib]))
    end

    defaultto :latest
  end

  def generate
    options = { :name => @title }
    [ Puppet::Type.type(:cs_commit).new(options) ]
  end

  autorequire(:service) do
    [ 'corosync' ]
  end
end
