Puppet::Type.newtype(:cs_shadow) do
  @doc = "cs_shadow resources represent a Corosync shadow CIB. Any corosync
    resources defined with 'cib' set to the title of a cs_shadow resource
    will not become active until all other resources with the same cib
    value have also been applied."

  newparam(:cib) do
    desc 'Name of the CIB to begin tracking changes against.'
    isnamevar
  end

  newparam(:autocommit, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc "Whether to generate a cs_commit or not. Can be used to create shadow
      CIB without committing them."
    defaultto :true
  end

  newproperty(:epoch) do
    desc 'Implementation detail. DO NOT SET DIRECTLY.'

    def sync
      provider.sync(@resource[:cib])
    end

    def retrieve
      provider.get_epoch(@resource[:cib])
    end

    def insync?(_is)
      provider.insync?(@resource[:cib])
    end

    def change_to_s(currentvalue, _newvalue)
      super(currentvalue, provider.get_epoch(@resource[:cib]))
    end

    defaultto :latest
  end

  def generate
    return [] if self[:autocommit] != true

    options = { name: @title }
    [Puppet::Type.type(:cs_commit).new(options)]
  end

  autorequire(:service) do
    %w[corosync pacemaker]
  end
end
