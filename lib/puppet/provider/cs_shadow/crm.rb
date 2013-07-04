require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_shadow).provide(:crm, :parent => Puppet::Provider::Corosync) do
  commands :crm => 'crm'

  def self.instances
    block_until_ready
    []
  end

  def exists?
	# Dummy. The shadow file is created in each of the providers supporting shadow files.
    true
  end

  def refresh
    flushShadow(@resource[:name])
  end
end
