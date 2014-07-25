require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_commit).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  commands :crm_shadow => 'crm_shadow'

  def self.instances
    block_until_ready
    []
  end

  def sync(cib)
    crm_shadow('--commit', cib)
  end
end
