# This file contains helpers that are specific to this module

def expect_commands(patterns)
  command_suite = sequence('pcs commands')
  Array(patterns).each do |pattern|
    Puppet::Util::Execution.expects(:execute).once.with do |*args|
      cmdline = args[0].join(' ')
      pattern.match(cmdline)
    end.in_sequence(command_suite).returns(
      Puppet::Util::Execution::ProcessOutput.new('', 0)
    )
  end
end

def not_expect_commands(patterns)
  Array(patterns).each do |pattern|
    Puppet::Util::Execution.expects(:execute).never.with do |*args|
      cmdline = args[0].join(' ')
      pattern.match(cmdline)
    end
  end
end

shared_context 'pcs' do
  before do
    described_class.stubs(:command).with(:pcs).returns 'pcs'
    described_class.stubs(:command).with(:cibadmin).returns 'cibadmin'
    described_class.expects(:block_until_ready).returns(nil).at_most(1)
  end
end

def pcs_load_cib(cib)
  Puppet::Util::Execution.expects(:execute).with(%w(pcs cluster cib), failonfail: true, combine: true).at_least_once.returns(
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
