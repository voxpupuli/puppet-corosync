# frozen_string_literal: true

# This file contains helpers that are specific to this module

def corosync_stack(facts)
  case facts[:os]['family']
  when 'RedHat'
    corosync_stack = 'pcs'
    pcs_version = if facts[:os]['release']['major'].to_i > 7
                    '0.10.0'
                  else
                    '0.9.0'
                  end
  when 'Debian'
    corosync_stack = 'pcs'
    pcs_version = '0.10.0'
  when 'Suse'
    corosync_stack = 'crm'
    pcs_version = ''
  else
    corosync_stack = 'crm'
    pcs_version = ''
  end
  { provider: corosync_stack, pcs_version: pcs_version }
end

def expect_commands(patterns)
  Array(patterns).each do |pattern|
    allow(Puppet::Util::Execution).to receive(:execute) do |*args|
      cmdline = args[0].join(' ')
      pattern.match(cmdline)
    end.and_return(
      Puppet::Util::Execution::ProcessOutput.new('', 0)
    )
  end
end

def not_expect_commands(patterns)
  Array(patterns).each do |pattern|
    allow(Puppet::Util::Execution).to receive(:execute) do |*args|
      cmdline = args[0].join(' ')
      !pattern.match(cmdline)
    end
  end
end

shared_context 'pcs' do
  before do
    allow(described_class).to receive(:command).with(:pcs).and_return('pcs')
    allow(described_class).to receive(:command).with(:cibadmin).and_return('cibadmin')
    allow(described_class).to receive(:block_until_ready).and_return(nil)
  end
end

def pcs_load_cib(cib)
  allow(Puppet::Util::Execution).to receive(:execute).and_return(
    Puppet::Util::Execution::ProcessOutput.new(cib, 0)
  )
end

def create_cs_location_resource(primitive)
  cs_location_class = Puppet::Type.type(:cs_location)
  cs_location_class.new(
    name: "#{primitive}_location",
    primitive: primitive
  )
end

def create_cs_location_resource_with_cib(primitive, cib)
  cs_location_class = Puppet::Type.type(:cs_location)
  cs_location_class.new(
    name: "#{primitive}_location",
    primitive: primitive,
    cib: cib
  )
end

def create_cs_group_resource(name, primitives)
  cs_group_class = Puppet::Type.type(:cs_group)
  cs_group_class.new(
    name: name,
    primitives: primitives
  )
end

def create_cs_group_resource_with_cib(name, primitives, cib)
  cs_group_class = Puppet::Type.type(:cs_group)
  cs_group_class.new(
    name: name,
    primitives: primitives,
    cib: cib
  )
end

def create_cs_clone_resource(primitive)
  cs_clone_class = Puppet::Type.type(:cs_clone)
  cs_clone_class.new(
    name: "#{primitive}_clone",
    primitive: primitive
  )
end

def create_cs_clone_resource_with_group(group)
  cs_clone_class = Puppet::Type.type(:cs_clone)
  cs_clone_class.new(
    name: "#{group}_clone",
    group: group
  )
end

def create_cs_clone_resource_with_cib(primitive, cib)
  cs_clone_class = Puppet::Type.type(:cs_clone)
  cs_clone_class.new(
    name: "#{primitive}_clone",
    primitive: primitive,
    cib: cib
  )
end

def create_cs_primitive_resource(primitive)
  cs_primitive_class = Puppet::Type.type(:cs_primitive)
  cs_primitive_class.new(
    name: primitive
  )
end

def create_cs_shadow_resource(cib)
  cs_shadow_class = Puppet::Type.type(:cs_shadow)
  cs_shadow_class.new(
    name: cib
  )
end

def create_service_resource(name)
  cs_shadow_class = Puppet::Type.type(:service)
  cs_shadow_class.new(
    name: name
  )
end

def create_catalog(*resources)
  catalog = Puppet::Resource::Catalog.new
  resources.each do |resource|
    catalog.add_resource resource
  end

  catalog
end
