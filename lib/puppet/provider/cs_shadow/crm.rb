require File.join(File.dirname(__FILE__), '..', 'corosync')

Puppet::Type.type(:cs_shadow).provide(:crm, :parent => Puppet::Provider::Corosync) do
  commands :crm => 'crm'

  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    crm "cib", "new", cib
  end
end
