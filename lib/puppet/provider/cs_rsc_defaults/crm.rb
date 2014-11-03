require 'pathname' # JJM WORK_AROUND #14073
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'crmsh'

Puppet::Type.type(:cs_rsc_defaults).provide(:crm, :parent => Puppet::Provider::Crmsh) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of Corosync global defaults for resource options.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm           => 'crm'
  commands :cibadmin      => 'cibadmin'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    if Puppet::PUPPETVERSION.to_f < 3.4
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    else
      raw = Puppet::Util::Execution.execute(cmd)
      status = raw.exitstatus
    end
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//configuration/rsc_defaults/meta_attributes/nvpair') do |e|
      items = e.attributes
      rsc_defaults = { :name => items['name'], :value => items['value'] }

      rsc_defaults_instance = {
        :name       => rsc_defaults[:name],
        :ensure     => :present,
        :value      => rsc_defaults[:value],
        :provider   => self.name
      }
      instances << new(rsc_defaults_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name   => @resource[:name],
      :ensure => :present,
      :value  => @resource[:value],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing resource default')
    cibadmin('--scope', 'rsc_defaults', '--delete', '--xpath', "//configuration/rsc_defaults/meta_attributes/nvpair[@name='#{resource[:name]}']")
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
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      # clear this on properties, in case it's set from a previous
      # run of a different corosync type
      ENV['CIB_shadow'] = nil
      crm('configure', 'rsc_defaults', '$id="rsc-options"', "#{@property_hash[:name]}=#{@property_hash[:value]}")
    end
  end
end
