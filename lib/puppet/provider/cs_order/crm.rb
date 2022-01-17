# frozen_string_literal: true
begin
  require 'puppet_x/voxpupuli/corosync/provider/crmsh'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/crmsh'
end

Puppet::Type.type(:cs_order).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of current primitive start orders on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands crm: 'crm'

  mk_resource_methods

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:crm), 'configure', 'show', 'xml']
    raw, = run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_order') do |e|
      items = e.attributes

      first = if items['first-action']
                "#{items['first']}:#{items['first-action']}"
              else
                items['first']
              end

      second = if items['then-action']
                 "#{items['then']}:#{items['then-action']}"
               else
                 items['then']
               end

      kind = items['kind'] || 'Mandatory'

      symmetrical = if items['symmetrical']
                      (items['symmetrical'] == 'true')
                    else
                      # Default: symmetrical is true unless explicitly defined.
                      true
                    end

      order_instance = {
        name: items['id'],
        ensure: :present,
        first: first,
        second: second,
        score: items['score'],
        kind: kind,
        symmetrical: symmetrical,
        provider: name
      }
      instances << new(order_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      first: @resource[:first],
      second: @resource[:second],
      score: @resource[:score],
      symmetrical: @resource[:symmetrical],
      kind: @resource[:kind],
      cib: @resource[:cib]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing order directive')
    self.class.run_command_in_cib([command(:crm), 'configure', 'delete', @resource[:name]], @resource[:cib])
    @property_hash.clear
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    return if @property_hash.empty?

    updated = 'order '
    updated << "#{@property_hash[:name]} "
    if @property_hash[:score]
      updated << "#{@property_hash[:score]}: "
    elsif feature? :kindness
      updated << "#{@property_hash[:kind]}: "
    end
    updated << "#{@property_hash[:first]} #{@property_hash[:second]} symmetrical=#{@property_hash[:symmetrical]}"
    debug("Loading update: #{updated}")
    Tempfile.open('puppet_crm_update') do |tmpfile|
      tmpfile.write(updated)
      tmpfile.flush
      self.class.run_command_in_cib([command(:crm), 'configure', 'load', 'update', tmpfile.path.to_s], @resource[:cib])
    end
  end
end
