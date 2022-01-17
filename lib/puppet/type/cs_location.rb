# frozen_string_literal: true

Puppet::Type.newtype(:cs_location) do
  @doc = "Type for manipulating corosync/pacemaker resource location.
    More information on Corosync/Pacemaker colocation can be found here:

    * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html"

  ensurable

  feature :discovery, 'Support for the resource_discovery parameter'

  newparam(:name) do
    desc "Identifier of the location entry.  This value needs to be unique
      across the entire Corosync/Pacemaker configuration since it doesn't have
      the concept of name spaces per type."

    isnamevar
  end

  newproperty(:primitive) do
    desc 'The corosync resource primitive to have a location applied.  '
  end

  newproperty(:node_name) do
    desc 'The corosync node_name where the resource should be located.  '
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

  newproperty(:resource_discovery, required_features: :discovery) do
    desc 'Whether Pacemaker should perform resource discovery on this
    node for the specified resource. It matches the resource-discovery
    location property in pacemaker'
  end

  newproperty(:score) do
    desc "The priority of this location.  Primitives can be a part of
      multiple location groups and so there is a way to control which
      primitives get priority when forcing the move of other primitives.
      This value can be an integer but is often defined as the string
      INFINITY."

    defaultto 'INFINITY'
  end

  newproperty(:rules, array_matching: :all) do
    desc "The rules of this location.  This is an array of hashes where
      each hash contains an array of one or more expressions.

      Example:

        cs_location { 'vip-ping-connected':
          primitive => 'vip',
          rules     => [
            'vip-ping-exclude-rule' => {
              'score'      => '-INFINITY',
              'expression' => [
                { 'attribute' => 'pingd',
                  'operation' => 'lt',
                  'value'     => '100',
                },
              ],
            },
            'vip-ping-prefer-rule'  => {
              'score-attribute' => 'pingd',
              'expression'      => [
                { 'attribute' => 'pingd',
                  'operation' => 'defined',
                },
              ],
            },
          ],
        }"

    def insync?(is)
      ((should - is) + (is - should)).empty?
    end
  end

  autorequire(:cs_shadow) do
    autos = []
    autos << @parameters[:cib].value if @parameters[:cib]
    autos
  end

  autorequire(:service) do
    %w[corosync pacemaker]
  end

  %i[cs_primitive cs_clone cs_group].each do |type|
    autorequire(type) do
      autos = []
      autos << unmunge_cs_primitive(should(:primitive)) if should(:primitive)

      autos
    end
  end

  def unmunge_cs_primitive(name)
    name = name.split(':')[0]
    name = name[3..-1] if name.start_with? 'ms_'

    name
  end

  validate do
    raise Puppet::Error, 'Location constraints dictate that node_name and rules cannot co-exist for this type.' if [self[:node_name], self[:rules]].compact.length > 1
  end
end
