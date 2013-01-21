require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_shadow).provide(:crm, :parent => Puppet::Provider::Corosync) do
  commands :crm_attribute => 'crm_attribute'
  if Puppet::PUPPETVERSION.to_f < 3
    commands :crm => 'crm'
  else
    has_command(:crm, 'crm') { environment :HOME => '/root' }
  end

  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    begin
      crm('cib', 'delete', cib)
    rescue => e
      # If the CIB doesn't exist, we don't care.
    end
    crm('cib', 'new', cib)
  end
end
