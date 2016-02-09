Puppet::Type.newtype(:cs_commit) do
  @doc = "This type is an implementation detail. DO NOT use it directly"

  feature :refreshable, "The provider can execute the commit.",
    :methods => [:commit]

  newparam(:cib) do
    def sync
      provider.sync(self.should)
    end

    def retrieve
      :absent
    end

    def insync?(is)
      false
    end

    defaultto { @resource[:name] }
  end

  newparam(:name) do
    isnamevar
  end

  def refresh
    provider.commit
  end

  autorequire(:cs_shadow) do
    [ @parameters[:cib] ]
  end

  autorequire(:service) do
    [ 'corosync' ]
  end

  if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '4.0') >= 0
    autosubscribe(:cs_primitive) do
      resources_with_cib :cs_primitive
    end

    autosubscribe(:cs_colocation) do
      resources_with_cib :cs_colocation
    end

    autosubscribe(:cs_location) do
      resources_with_cib :cs_location
    end

    autosubscribe(:cs_order) do
      resources_with_cib :cs_order
    end
  else 
    autorequire(:cs_primitive) do
      resources_with_cib :cs_primitive
    end

    autorequire(:cs_colocation) do
      resources_with_cib :cs_colocation
    end

    autorequire(:cs_location) do
      resources_with_cib :cs_location
    end

    autorequire(:cs_order) do
      resources_with_cib :cs_order
    end
  end

  def resources_with_cib(cib)
    autos = []

    catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type(cib)) and param = r.parameter(:cib) and param.value == @parameters[:cib] }.each do |r|
      autos << r
    end

    autos
  end
end
