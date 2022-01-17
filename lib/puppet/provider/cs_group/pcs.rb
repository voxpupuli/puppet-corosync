# frozen_string_literal: true
begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_group).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  desc 'Provider to add, delete, manipulate primitive groups.'

  defaultfor operatingsystem: %i[fedora centos redhat]

  # Path to the pcs binary for interacting with the cluster configuration.
  commands pcs: '/usr/sbin/pcs'

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//group') do |e|
      primitives = []

      unless e.elements['primitive'].nil?
        e.each_element do |p|
          primitives << p.attributes['id']
        end
      end

      group_instance = {
        name: e.attributes['id'],
        ensure: :present,
        primitives: primitives,
        provider: name,
        new: false
      }
      instances << new(group_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      primitives: Array(@resource[:primitives]),
      new: true
    }
    @property_hash[:cib] = @resource[:cib] unless @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item but first, like primitives,
  # we need to stop the group.
  def destroy
    debug('Removing group')
    self.class.run_command_in_cib([command(:pcs), 'resource', 'ungroup', @property_hash[:name]], @resource[:cib])
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitives
    @property_hash[:primitives]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def primitives=(should)
    @property_hash[:primitives] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the pcs command.
  def flush
    return if @property_hash.empty?

    if @property_hash[:new] == false
      debug('Removing group')
      self.class.run_command_in_cib([command(:pcs), 'resource', 'ungroup', @property_hash[:name]], @resource[:cib])
    end

    cmd = [command(:pcs), 'resource', 'group', 'add', (@property_hash[:name]).to_s]
    cmd += @property_hash[:primitives]
    self.class.run_command_in_cib(cmd, @resource[:cib])
  end
end
