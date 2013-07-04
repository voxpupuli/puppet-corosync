class Puppet::Provider::Corosync < Puppet::Provider

  # Yep, that's right we are parsing XML...FUN! (It really wasn't that bad)
  require 'rexml/document'

  initvars
  commands :crm_attribute => 'crm_attribute'

  # Corosync takes a while to build the initial CIB configuration once the
  # service is started for the first time.  This provides us a way to wait
  # until we're up so we can make changes that don't disappear in to a black
  # hole.
  def self.ready?
    cmd =  [ command(:crm_attribute), '--type', 'crm_config', '--query', '--name', 'dc-version' ]
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    if status == 0
      return true
    else
      return false
    end
  end

  def self.block_until_ready(timeout = 120)
    Timeout::timeout(timeout) do
      until ready?
        debug('Corosync not ready, retrying')
        sleep 2
      end
      # Sleeping a spare two since it seems that dc-version is returning before
      # It is really ready to take config changes, but it is close enough.
      # Probably need to find a better way to check for reediness.
      sleep 2
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if res = resources[prov.name.to_s]
        res.provider = prov
      end
    end
  end

  def exists?
    self.class.block_until_ready
    debug(@property_hash.inspect)
    !(@property_hash[:ensure] == :absent or @property_hash.empty?)
  end

  # Sets up a clean shadow CIB based on the current cluster. Gets executed by every
  # resource which supports CIB usage in their flush methods, right before actually
  # pushing loading their update. This function ensures a temporary CIB exists.
  def setupShadow(cib)
    # If this is the first resource in the Puppet run to commit with a CIB, generate
    # the unique CIB name for this Puppet run.
    if ENV['CIB_shadow'].nil?
        Puppet.debug "Creating shadow cib #{cib} from live cluster"
        # Delete the CIB first if it exists
        crm('cib', 'delete', cib) if system("crm cib use #{cib} &> /dev/null")==true
        # Create the new CIB based on the current cluster
        crm('cib', 'new', cib)
    end
    # Set environment variable: this will cause 'crm' command to use this CIB.
    ENV['CIB_shadow'] = cib
  end

  # Flushing commits the contents of the shadow CIB to the live configuration.
  # Each resource supporting shadow CIBs commits to the above created CIB.
  # Then, they notify the cs_shadow resource which actually commits to the cluster
  # using this function.
  def flushShadow(cib)
    Puppet.debug "Flushing out changes from shadow cib #{cib} to live cluster"
    crm('cib', 'commit', cib) unless cib.nil?
  end
end
