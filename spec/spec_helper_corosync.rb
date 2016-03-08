# This file contains helpers that are specific to this module

def expect_commands(patterns)
  command_suite = sequence('pcs commands')
  Array(patterns).each do |pattern|
    if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
      Puppet::Util::SUIDManager.expects(:run_and_capture).once.with { |*args|
        cmdline = args[0].join(' ')
        pattern.match(cmdline)
      }.in_sequence(command_suite).returns(['', 0])
    else
      Puppet::Util::Execution.expects(:execute).once.with { |*args|
        cmdline = args[0].join(' ')
        pattern.match(cmdline)
      }.in_sequence(command_suite).returns(
        Puppet::Util::Execution::ProcessOutput.new('', 0)
      )
    end
  end
end

def not_expect_commands(patterns)
  Array(patterns).each do |pattern|
    if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
      Puppet::Util::SUIDManager.expects(:run_and_capture).never.with { |*args|
        cmdline = args[0].join(' ')
        pattern.match(cmdline)
      }
    else
      Puppet::Util::Execution.expects(:execute).never.with { |*args|
        cmdline = args[0].join(' ')
        pattern.match(cmdline)
      }
    end
  end
end
