require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'crmsh'

Puppet::Type.type(:cs_clone).provide(:crm, :parent => Puppet::Provider::Crmsh) do
  desc ' Fill this in '

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm => 'crm'

  # given an XML element containing some <nvpair>s, return a hash. Return an
  # empty hash if `e` is nil.
  def self.nvpairs_to_hash(e)
    return {} if e.nil?

    hash = {}
    e.each_element do |i|
      hash[(i.attributes['name'])] = i.attributes['value']
    end

    hash
  end

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

    doc.root.elements['configuration'].elements['resources'].each_element('clone') do |e|
      clone_instance = {
        :name      => e.attributes['id'].to_sym,
        :metadata  => nvpairs_to_hash(e.elements['meta_attributes']),
        :primitive => e.elements['primitive'].attributes['id'].to_sym,
      }

      instances << new(clone_instance)
    end

    instances
  end

  
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :primitive  => @resource[:primitive],
      :metadata   => @resource[:metadata],
    }
    @property_hash[:cib] = @resource[:cib] if ! @resource[:cib].nil?
  end

  
  def destroy
    debug('Stopping primitive before removing it')
    crm('resource', 'stop', @resource[:name])
    debug('Revmoving primitive')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
  end


  def primitive
    @property_hash[:primitive]
  end

  
  def primitive=(should)
    @property_hash[:primitive] = should
  end

  
  def metadata
    @property_hash[:metadata]
  end


  def metadata=(should)
    @property_hash[:metadata] = should
  end

  def flush
    unless @property_hash.empty?
      updated = 'clone '
      updated << "#{@property_hash[:name]} #{@property_hash[:primitive]} "
      unless @property_hash[:metadata].empty?
        updated << 'meta '
        @property_hash[:metadata].each do |k,v|
          updated << "#{k}=#{v} "
        end
      end
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated)
        tmpfile.flush
        ENV['CIB_shadow'] = @resource[:cib]
        crm('configure', 'load', 'update', tmpfile.path.to_s)
      end
    end
  end

end

