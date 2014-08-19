require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_clone).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of current primitive start orders on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm => 'crm'
  commands :crm_attribute => 'crm_attribute'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:crm), 'configure', 'show', 'xml' ]

    if Puppet::PUPPETVERSION.to_f < 3.4
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    else
      raw = Puppet::Util::Execution.execute(cmd, :failonfail => false)
      status = raw.exitstatus
    end

    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//clone') do |e|

      clone = {}

      items = e.attributes

      clone.merge!({
        items['id'].to_sym => {
        }
      })

      clone[items['id'].to_sym][:metadata] = {}
      #clone[items['id'].to_sym][:primitive] = []

      if ! e.elements['primitive'].nil?
         clone[items['id'].to_sym][:primitive] = e.elements['primitive'].attributes['id']
         #e.elements.each("primitive") do |p|
         #   clone[items['id'].to_sym][:primitive] << p.attributes['id']
         #end
      end

      if ! e.elements['meta_attributes'].nil?
        e.elements['meta_attributes'].each_element do |m|
          clone[items['id'].to_sym][:metadata][(m.attributes['name'])] = m.attributes['value']
        end
      end

      clone_instance = {
        :name       => clone.first[0],
        :ensure     => :present,
        :primitive  => clone.first[1][:primitive],
	:metadata   => clone.first[1][:metadata],
        :provider   => self.name
      }
      instances << new(clone_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :metadata   => @resource[:metadata],
      :primitive  => @resource[:primitive],
      :cib        => @resource[:cib],
    }
    @property_hash[:metadata] = @resource[:metadata] if ! @resource[:metadata].nil?
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Stopping clone before removing it')
    crm('resource', 'stop', @resource[:name])
    debug('Revmoving order directive')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
  end

  # Getters that obtains the first and second primitives and score in our
  # ordering definintion that have been populated by prefetch or instances
  # (depends on if your using puppet resource or not).
  def primitive
    @property_hash[:primitive]
  end

  def metadata
    @property_hash[:metadata]
  end

  # Our setters for the first and second primitives and score.  Setters are
  # used when the resource already exists so we just update the current value
  # in the property hash and doing this marks it to be flushed.
  def primitive=(should)
    @property_hash[:primitive] = should.sort
  end

  def metadata=(should)
    @property_hash[:metadata] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
      unless @property_hash.empty?
         unless @property_hash[:metadata].empty?
            metadatas = 'meta '
            @property_hash[:metadata].each_pair do |k,v|
            metadatas << "#{k}=#{v} "
         end
      end
      updated = 'clone '
      updated << "#{@property_hash[:name]} #{@property_hash[:primitive]} "
      updated << "#{metadatas} " unless metadatas.nil?
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated)
        tmpfile.flush
        ENV['CIB_shadow'] = @resource[:cib]
        crm('configure', 'load', 'update', tmpfile.path.to_s)
      end
    end
  end
end
