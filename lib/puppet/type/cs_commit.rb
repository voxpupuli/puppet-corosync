# frozen_string_literal: true

Puppet::Type.newtype(:cs_commit) do
  @doc = 'Final commit statement which triggers the synchronous application of
          all primitive changes which reference this CIB. Do not generate more
          than one cs_commit referencing the same CIB for a given cluster!'

  feature :refreshable, 'The provider can execute the commit.', methods: [:commit]

  newparam(:cib) do
    desc 'Name of the CIB to commit. This value defaults to the name of
          the cs_commit resource.'

    def insync?(_is)
      true
    end

    defaultto { @resource[:name] }
  end

  newparam(:name) do
    desc 'Name of the CIB to commit. See the cib parameter for more detail.'
    isnamevar
  end

  def refresh
    provider.commit
  end

  autorequire(:service) do
    %w[corosync pacemaker]
  end

  autorequire(:cs_shadow) do
    autos = []
    autos << @parameters[:cib].value if @parameters[:cib]
    autos
  end

  if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '4.0').negative?
    autorequire(:cs_primitive) do
      resources_with_cib :cs_primitive
    end

    autorequire(:cs_property) do
      resources_with_cib :cs_property
    end

    autorequire(:cs_colocation) do
      resources_with_cib :cs_colocation
    end

    autorequire(:cs_location) do
      resources_with_cib :cs_location
    end

    autorequire(:cs_group) do
      resources_with_cib :cs_group
    end

    autorequire(:cs_order) do
      resources_with_cib :cs_order
    end
  else
    autosubscribe(:cs_primitive) do
      resources_with_cib :cs_primitive
    end

    autosubscribe(:cs_property) do
      resources_with_cib :cs_property
    end

    autosubscribe(:cs_colocation) do
      resources_with_cib :cs_colocation
    end

    autosubscribe(:cs_location) do
      resources_with_cib :cs_location
    end

    autosubscribe(:cs_group) do
      resources_with_cib :cs_group
    end

    autosubscribe(:cs_order) do
      resources_with_cib :cs_order
    end
  end

  def resources_with_cib(resource_type)
    autos = []
    catalog.resources.select { |r| r.is_a?(Puppet::Type.type(resource_type)) && r.should(:cib) == should(:cib) }.each do |r|
      autos << r
    end

    autos
  end
end
