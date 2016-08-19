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
