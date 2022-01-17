begin
  require 'puppet_x/voxpupuli/corosync/provider/pcs'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/pcs'
end

Puppet::Type.type(:cs_rsc_defaults).provide(:pcs, parent: PuppetX::Voxpupuli::Corosync::Provider::Pcs) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of Corosync global defaults for resource options.'

  defaultfor operatingsystem: %i[fedora centos redhat]

  # Path to the pcs binary for interacting with the cluster configuration.
  commands pcs: 'pcs'

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//configuration/rsc_defaults/meta_attributes/nvpair') do |e|
      items = e.attributes
      rsc_defaults = { name: items['name'], value: items['value'] }

      rsc_defaults_instance = {
        name: rsc_defaults[:name],
        ensure: :present,
        value: rsc_defaults[:value],
        provider: name
      }
      instances << new(rsc_defaults_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      value: @resource[:value]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing resource default')
    cmd = [command(:pcs), 'resource', 'defaults', (@property_hash[:name]).to_s + '=']
    self.class.run_command_in_cib(cmd, @resource[:cib])
    @property_hash.clear
  end

  # Getters that obtains the first and second primitives and score in our
  # ordering definintion that have been populated by prefetch or instances
  # (depends on if your using puppet resource or not).
  def value
    @property_hash[:value]
  end

  # Our setters for the first and second primitives and score.  Setters are
  # used when the resource already exists so we just update the current value
  # in the property hash and doing this marks it to be flushed.
  def value=(should)
    @property_hash[:value] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the pcs command.
  def flush
    return if @property_hash.empty?

    # clear this on properties, in case it's set from a previous
    # run of a different corosync type
    cmd = [command(:pcs), 'resource', 'defaults', "#{@property_hash[:name]}=#{@property_hash[:value]}"]
    self.class.run_command_in_cib(cmd, @resource[:cib])
  end
end
