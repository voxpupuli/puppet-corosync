# This file comes from puppetlabs-stdlib
# which is licensed under the Apache-2.0 License.
# https://github.com/puppetlabs/puppetlabs-stdlib
# (c) 2015-2015 Puppetlabs and puppetlabs-stdlib contributors

require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'
install_ca_certs unless ENV['PUPPET_INSTALL_TYPE'] =~ %r{pe}i
install_module_on(hosts)
install_module_dependencies_on(hosts)

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    hosts.each do |host|
      if host[:platform] =~ %r{el-7-x86_64} && host[:hypervisor] =~ %r{docker}
        on(host, "sed -i '/nodocs/d' /etc/yum.conf")
      end
      # For Debian 8 "jessie", we need
      # - pacemaker and crmsh delivered in jessie-backports only
      # - openhpid post-install may fail (https://bugs.debian.org/785287)
      if fact('os.family') == 'Debian' && fact('os.release.major') == '8'
        on host, 'echo deb http://ftp.debian.org/debian jessie-backports main >> /etc/apt/sources.list'
        on host, 'apt-get update && apt-get install -y openhpid', acceptable_exit_codes: [0, 1, 100]
      end
    end
  end
end

def cleanup_cs_resources
  pp = <<-EOS
      resources { 'cs_clone' :
        purge => true,
      }
      resources { 'cs_group' :
        purge => true,
      }
      resources { 'cs_colocation' :
        purge => true,
      }
      resources { 'cs_location' :
        purge => true,
      }
    EOS

  apply_manifest(pp, catch_failures: true, debug: false, trace: true)
  apply_manifest(pp, catch_changes: true, debug: false, trace: true)

  pp = <<-EOS
      resources { 'cs_primitive' :
        purge => true,
      }
    EOS

  apply_manifest(pp, catch_failures: true, debug: false, trace: true)
  apply_manifest(pp, catch_changes: true, debug: false, trace: true)
end

RSpec.shared_context 'with faked facts' do
  let(:facts_d) do
    puppet_version = get_puppet_version
    if fact('osfamily') =~ %r{windows}i
      if fact('kernelmajversion').to_f < 6.0
        'C:/Documents and Settings/All Users/Application Data/PuppetLabs/facter/facts.d'
      else
        'C:/ProgramData/PuppetLabs/facter/facts.d'
      end
    elsif Puppet::Util::Package.versioncmp(puppet_version, '4.0.0') < 0 && fact('is_pe', '--puppet') == 'true'
      '/etc/puppetlabs/facter/facts.d'
    else
      '/etc/facter/facts.d'
    end
  end

  before do
    # No need to create on windows, PE creates by default
    shell("mkdir -p '#{facts_d}'") if fact('osfamily') !~ %r{windows}i
  end

  after do
    shell("rm -f '#{facts_d}/fqdn.txt'", acceptable_exit_codes: [0, 1])
  end

  def fake_fact(name, value)
    shell("echo #{name}=#{value} > '#{facts_d}/#{name}.txt'")
  end
end
