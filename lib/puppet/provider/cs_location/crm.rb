require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_location).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.
  commands :crm => 'crm'
  commands :crm_attribute => 'crm_attribute'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_location') do |e|
      items = e.attributes

      rule = {}

      if ! e.elements['rule'].nil?
         e.elements.each("rule") do |r|
	 rule = { 'score' => r.attributes['score'], 'operation' => r.attributes['boolean-op'], 'expressions' => [] }
            r.elements.each("expression") do |x|
               if x.attributes['value']
                  rule['expressions'] << "#{x.attributes['attribute']} #{x.attributes['operation']} #{x.attributes['value']}"
               else
                  rule['expressions'] << "#{x.attributes['operation']} #{x.attributes['attribute']}"
               end
           end
         end
      end

      location_instance = {
        :name       => items['id'],
        :ensure     => :present,
        :rsc        => items['rsc'],
        :host       => items['node'],
        :rules      => rule.to_s,
        :score      => items['score'],
        :provider   => self.name
      }
      instances << new(location_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :rsc        => @resource[:rsc],
      :cib        => @resource[:cib],
    }
    @property_hash[:host] = @resource[:host] if ! @resource[:host].nil?
    @property_hash[:score] = @resource[:score] if ! @resource[:score].nil?
    @property_hash[:rules] = @resource[:rules] if ! @resource[:rules].nil?
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Revmoving location')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def rsc
    @property_hash[:rsc]
  end

  # Getter that obtains the our score that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def score
    @property_hash[:score]
  end

  def host
    @property_hash[:host]
  end

  def rules
    @property_hash[:rules].sort
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def rsc=(should)
    @property_hash[:rsc] = should
  end

  def score=(should)
    @property_hash[:score] = should
  end

  def host=(should)
    @property_hash[:host] = should
  end

  def rules=(should)
    @property_hash[:rules] = should.sort
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush

    unless @property_hash.empty?
      updated = "location #{@property_hash[:name]} #{@property_hash[:rsc]} "
      if ! @property_hash[:host].nil? and ! @property_hash[:score].nil?
         updated << "#{@property_hash[:score]}: #{@property_hash[:host]}"
      else
         unless @property_hash[:rules].empty?
            @property_hash[:rules].each do |r|
               updated << "rule #{r['score']}: "
               unless r['expressions'].empty?
                  i = r['expressions'].size
                  r['expressions'].each do |e|
                     i = i - 1
                     updated << "#{e} "
                     updated << "#{r['operation']} " if i > 0
                  end
               end
            end
         end
      end

      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated)
        tmpfile.flush
        ENV["CIB_shadow"] = @resource[:cib]
        crm('configure', 'load', 'update', tmpfile.path.to_s)
      end
    end
  end
end
