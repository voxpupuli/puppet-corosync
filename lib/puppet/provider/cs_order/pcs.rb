require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_order).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of current primitive start orders on the system; add, delete, or adjust various
        aspects.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  # Path to the pcs binary for interacting with the cluster configuration.
  commands :pcs => 'pcs'

  mk_resource_methods

  def self.instances
    block_until_ready

    instances = []

    cmd = [command(:pcs), 'cluster', 'cib']
    raw, = Puppet::Provider::Pacemaker.run_command_in_cib(cmd)
    doc = REXML::Document.new(raw)

    constraints = doc.root.elements['configuration'].elements['constraints']
    unless constraints.nil?
      constraints.each_element('rsc_order') do |e|
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
        score = if items['score']
                  items['score']
                else
                  'INFINITY'
                end
        kind = if items['kind']
                 items['kind']
               else
                 'Mandatory'
               end

        symmetrical = if items['symmetrical']
                        (items['symmetrical'] == 'true')
                      else
                        # Default: symmetrical is true unless explicitly defined.
                        true
                      end

        order_instance = {
          :name        => items['id'],
          :ensure      => :present,
          :first       => first,
          :second      => second,
          :score       => score,
          :kind        => kind,
          :symmetrical => symmetrical,
          :provider    => name,
          :new         => false
        }
        instances << new(order_instance)
      end
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name        => @resource[:name],
      :ensure      => :present,
      :first       => @resource[:first],
      :second      => @resource[:second],
      :score       => @resource[:score],
      :kind        => @resource[:kind],
      :symmetrical => @resource[:symmetrical],
      :new         => true
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing order directive')
    cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
    Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
    @property_hash.clear
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the pcs command.
  def flush
    unless @property_hash.empty?
      if @property_hash[:new] == false
        debug('Removing order directive')
        cmd = [command(:pcs), 'constraint', 'remove', @resource[:name]]
        Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
      end

      cmd = [command(:pcs), 'constraint', 'order']
      items = @property_hash[:first].split(':')
      cmd << items[1]
      cmd << items[0]
      cmd << 'then'
      items = @property_hash[:second].split(':')
      cmd << items[1]
      cmd << items[0]
      cmd << @property_hash[:score]
      cmd << "kind=#{@property_hash[:kind]}"
      cmd << "id=#{@property_hash[:name]}"
      cmd << "symmetrical=#{@property_hash[:symmetrical]}"
      Puppet::Provider::Pacemaker.run_command_in_cib(cmd, @resource[:cib])
    end
  end
end
