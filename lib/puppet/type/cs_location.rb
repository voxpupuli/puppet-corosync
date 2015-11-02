Puppet::Type.newtype(:cs_location) do
  @doc = "Type for manipulating corosync/pacemaker resource location.
    More information on Corosync/Pacemaker colocation can be found here:

    * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html"

  ensurable

  newparam(:name) do
    desc "Identifier of the location entry.  This value needs to be unique
      across the entire Corosync/Pacemaker configuration since it doesn't have
      the concept of name spaces per type."

    isnamevar
  end

  newproperty(:primitive) do
    desc "The corosync resource primitive to have a location applied.  "
  end

  newproperty(:node_name) do
    desc "The corosync node_name where the resource should be located.  "
  end

  newproperty(:resource_discovery) do
    desc "Whether Pacemaker should perform resource discovery on this node for the specified resource."
  end

  newparam(:cib) do
    desc "Corosync applies its configuration immediately. Using a CIB allows
      you to group multiple primitives and relationships to be applied at
      once. This can be necessary to insert complex configurations into
      Corosync correctly.

      This paramater sets the CIB this colocation should be created in. A
      cs_shadow resource with a title of the same name as this value should
      also be added to your manifest."
  end

  newproperty(:score) do
    desc "The priority of this location.  Primitives can be a part of
      multiple location groups and so there is a way to control which
      primitives get priority when forcing the move of other primitives.
      This value can be an integer but is often defined as the string
      INFINITY."

    defaultto 'INFINITY'
  end

  autorequire(:cs_shadow) do
    autos = []
    if @parameters[:cib]
      autos << @parameters[:cib].value
    end

    autos
  end

  autorequire(:cs_primitive) do
    autos = []
    if @parameters[:primitive]
      autos << @parameters[:primitive].value
    end

    autos
  end

  autorequire(:cs_clone) do
    autos = []
    if @parameters[:primitive]
      autos << @parameters[:primitive].value.slice("-clone")
    end

    autos
  end


  if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '4.0') >= 0
    autonotify(:cs_commit) do
      autos = []
      if @parameters[:cib]
        autos << @parameters[:cib].value
      end

      autos
    end
  end

  autorequire(:service) do
    [ 'corosync' ]
  end

end
