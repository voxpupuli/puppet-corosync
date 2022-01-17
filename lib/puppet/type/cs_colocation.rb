# frozen_string_literal: true
Puppet::Type.newtype(:cs_colocation) do
  @doc = "Type for manipulating corosync/pacemaker colocation.  Colocation
    is the grouping together of a set of primitives so that they travel
    together when one of them fails.  For instance, if a web server vhost
    is colocated with a specific ip address and the web server software
    crashes, the ip address with migrate to the new host with the vhost.

    More information on Corosync/Pacemaker colocation can be found here:

    * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html"

  ensurable

  newparam(:name) do
    desc "Identifier of the colocation entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

    isnamevar
  end

  newproperty(:primitives, array_matching: :all) do
    desc "At least two Pacemaker primitives to be located together. Order of primitives
      in colocation groups is important. In Pacemaker, a colocation of 2 primitives
      behaves different than a colocation between more than 2 primitives. Here the
      behavior is altered to be more consistent.
      Examples on how to define colocations here:
      - 2 primitives: [A, B] will cause A to be located first, and B will be located
        with A. This is different than how crm configure colocation works, because
        there [A, B] would mean colocate A with B, thus B should be located first.
      - multiple primitives: [A, B, C] will cause A to be located first, B next, and
        finally C. This is identical to how crm configure colocation works with
        multiple resources, it will add a colocated set.
      Property will raise an error if you do not provide an array containing at least
      two values. Values can be either the name of the primitive, or primitive:role.
      Notice, we can only interpret colocations of single sets, not multiple sets
      combined. In Pacemaker speak, this means we can support 'A B C' but not e.g.
      'A B (C D) E'. Feel free to contribute a patch for this."

    # Do some validation: the way Pacemaker colocation works we need to only accept
    # arrays with at least 2 values.
    def should=(value)
      super
      raise Puppet::Error, 'Puppet::Type::Cs_Colocation: The primitives property must be an array.' unless value.is_a? Array
      raise Puppet::Error, 'Puppet::Type::Cs_Colocation: The primitives property must be an array of at least one element.' if value.empty?

      @should
    end
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
    desc "The priority of this colocation.  Primitives can be a part of
      multiple colocation groups and so there is a way to control which
      primitives get priority when forcing the move of other primitives.
      This value can be an integer but is often defined as the string
      INFINITY."

    defaultto 'INFINITY'
  end

  autorequire(:cs_shadow) do
    autos = []
    autos << @parameters[:cib].value if @parameters[:cib]
    autos
  end

  autorequire(:service) do
    %w[corosync pacemaker]
  end

  def extract_primitives
    result = []
    unless @parameters[:primitives].should.nil?
      if @parameters[:primitives].should.first.is_a?(Hash)
        @parameters[:primitives].should.each do |colocation_set|
          result << colocation_set['primitives'] if colocation_set.key?('primitives')
        end
      end
      if @parameters[:primitives].should.first.is_a?(String)
        @parameters[:primitives].should.each do |val|
          result << unmunge_cs_primitive(val)
        end
      end
    end
    result.flatten
  end

  %i[cs_clone cs_primitive].each do |resource_type|
    autorequire(resource_type) do
      extract_primitives
    end
  end

  def unmunge_cs_primitive(name)
    name = name.split(':')[0]
    name = name[3..-1] if name.start_with? 'ms_'

    name
  end
end
