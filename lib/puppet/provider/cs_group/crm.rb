require 'puppet/provider/corosync'
Puppet::Type.type(:cs_group).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Provider to add, delete, manipulate primitive groups.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm => '/usr/sbin/crm'
  commands :crm_attribute => '/usr/sbin/crm_attribute'

  def self.instances

    instances = []

    cmd = []
    cmd << command(:crm)
    cmd << 'configure'
    cmd << 'show'
    cmd << 'xml'
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    doc = REXML::Document.new(raw)


    REXML::XPath.each(doc, '//group') do |e|

      items = e.attributes
      group = { :name => items['id'].to_sym }

      primitives = []
      
      if ! e.elements['primitive'].nil?
        e.each_element do |p|
          primitives << p.attributes['id']
        end
      end

      group_instance = {
        :name       => group[:name],
        :ensure     => :present,
        :primitives => primitives,
        :provider   => self.name
      }
      instances << new(group_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :primitives => @resource[:primitives]
    }
  end

  # Unlike create we actually immediately delete the item but first, like primitives,
  # we need to stop the group.
  def destroy
    cmd = [ command(:crm), 'resource', 'stop', @resource[:name] ]
    debug('Stopping group before removing it')
    Puppet::Util.exectute(cmd)
    cmd = []
    cmd << command(:crm)
    cmd << 'configure'
    cmd << 'delete'
    cmd << @resource[:name]
    debug('Revmoving group')
    Puppet::Util.execute(cmd)
    @property_hash.clear
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      updated = ''
      updated << "group "
      updated << "#{@property_hash[:name]} "
      updated << "#{@property_hash[:primitives].join(' ')}"
      cmd = []
      cmd << command(:crm)
      cmd << 'configure'
      cmd << 'load'
      cmd << 'update'
      cmd << '-'
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated)
        tmpfile.flush
        Puppet::Util.execute(cmd, :stdinfile => tmpfile.path.to_s)
      end
    end
  end
end
