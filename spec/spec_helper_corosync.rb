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
    described_class.expects(:block_until_ready).returns(nil).at_most(1)
  end
end

def pcs_load_cib(cib)
  Puppet::Util::Execution.expects(:execute).with(%w(pcs cluster cib), failonfail: true, combine: true).at_least_once.returns(
    Puppet::Util::Execution::ProcessOutput.new(cib, 0)
  )
end
