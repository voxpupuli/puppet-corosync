# frozen_string_literal: false

begin
  require 'puppet_x/voxpupuli/corosync/provider/crmsh'
rescue LoadError
  require 'pathname' # WORKAROUND #14073, #7788 and SERVER-973
  corosync = Puppet::Module.find('corosync')
  raise(LoadError, "Unable to find corosync module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless corosync

  require File.join corosync.path, 'lib/puppet_x/voxpupuli/corosync/provider/crmsh'
end

Puppet::Type.type(:cs_colocation).provide(:crm, parent: PuppetX::Voxpupuli::Corosync::Provider::Crmsh) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.
  commands crm: 'crm'

  defaultfor 'os.family': [:ubuntu]

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:crm), 'configure', 'show', 'xml']
    raw = Puppet::Util::Execution.execute(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_colocation') do |e|
      items = e.attributes

      if items['rsc']
        # The colocation is defined as a single rsc_colocation element. This means
        # the format is rsc and with-rsc. In the type we chose to always deal with
        # ordering in a sequential way, which is why we reverse their order.
        rsc = if items['rsc-role']
                "#{items['rsc']}:#{items['rsc-role']}"
              else
                items['rsc']
              end

        with_rsc = if items['with-rsc-role']
                     "#{items['with-rsc']}:#{items['with-rsc-role']}"
                   else
                     items['with-rsc']
                   end

        # Put primitives in chronological order, first 'with-rsc', then 'rsc'.
        primitives = [with_rsc, rsc]
      else
        # The colocation is defined as a rsc_colocation element wrapped around a single resource_set.
        # This happens automatically when you configure a colocation between more than 2 primitives.
        # Notice, we can only interpret colocations of single sets, not multiple sets combined.
        # In Pacemaker speak, this means we can support "A B C" but not e.g. "A B (C D) E".
        # Feel free to contribute a patch for this.
        primitives = []
        e.each_element('resource_set') do |rset|
          rsetitems = rset.attributes

          # If the resource set has a role, it will apply to all referenced resources.
          rsetrole = (rsetitems['role'])

          # Add all referenced resources to the primitives array.
          rset.each_element('resource_ref') do |rref|
            rrefitems = rref.attributes
            if rsetrole
              # Make sure the reference is stripped from a possible role
              rrefprimitive = rrefitems['id'].split(':')[0]
              # Always reuse the resource set role
              primitives.push("#{rrefprimitive}:#{rsetrole}")
            else
              # No resource_set role was set: just push the complete reference.
              primitives.push(rrefitems['id'])
            end
          end
        end
      end

      colocation_instance = {
        name: items['id'],
        ensure: :present,
        primitives: primitives,
        score: items['score'],
        provider: name
      }
      instances << new(colocation_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      name: @resource[:name],
      ensure: :present,
      primitives: @resource[:primitives],
      score: @resource[:score],
      cib: @resource[:cib]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing colocation')
    cmd = [command(:crm), 'configure', 'delete', @resource[:name]]
    self.class.run_command_in_cib(cmd, @resource[:cib])
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitives
    @property_hash[:primitives]
  end

  # Getter that obtains the our score that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def score
    @property_hash[:score]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def primitives=(should)
    @property_hash[:primitives] = should
  end

  def score=(should)
    @property_hash[:score] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    return if @property_hash.empty?

    primitives = if @property_hash[:primitives].count == 2
                   # crm configure colocation works backwards when exactly 2 primitives are
                   # defined. This is different from how >2 primitives are colocated, so to
                   # fix this the primitives are reversed.
                   @property_hash[:primitives].reverse
                 else
                   @property_hash[:primitives]
                 end
    updated = 'colocation '
    updated << "#{@property_hash[:name]} #{@property_hash[:score]}: #{primitives.join(' ')}"
    debug("Loading update: #{updated}")
    Tempfile.open('puppet_crm_update') do |tmpfile|
      tmpfile.write(updated)
      tmpfile.flush
      self.class.run_command_in_cib(['crm', 'configure', 'load', 'update', tmpfile.path.to_s], @resource[:cib])
    end
  end
end
