# frozen_string_literal: true

require 'spec_helper'

describe 'corosync' do
  let :params do
    { set_votequorum: false,
      multicast_address: '239.1.1.2' }
  end

  shared_examples_for 'corosync' do
    it { is_expected.to compile.with_all_deps }

    it 'does manage the corosync service' do
      is_expected.to contain_service('corosync').with(
        ensure: 'running'
      )
    end

    it 'validates the corosync configuration' do
      is_expected.to contain_file('/etc/corosync/corosync.conf').with_validate_cmd(
        '/usr/bin/env COROSYNC_MAIN_CONFIG_FILE=% /usr/sbin/corosync -t'
      )
    end

    context 'validates the corosncy configuration when config_validate_cmd is set' do
      let(:params) do
        super().merge(
          config_validate_cmd: '/usr/sbin/corosync -t -c'
        )
      end

      it 'validates with test_corosync_config_cmd' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_validate_cmd(
          '/usr/sbin/corosync -t -c'
        )
      end
    end

    context 'when manage_corosync_service is false' do
      let(:params) do
        super().merge(
          manage_corosync_service: false
        )
      end

      it 'is not managing corosync service' do
        is_expected.to compile
      end
    end

    context 'when set_votequorum is true' do
      let(:params) do
        super().merge(
          set_votequorum: true
        )
      end

      context 'when quorum_members is an array with 2 items' do
        let(:params) do
          super().merge(
            quorum_members: ['node1.test.org', 'node2.test.org']
          )
        end

        it 'configures votequorum' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node1\.test\.org\n\s*nodeid: 1}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node2\.test\.org\n\s*nodeid: 2}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end

        context 'with node ids' do
          let(:params) { super().merge(quorum_members_ids: [3, 11]) }

          it 'supports persistent node IDs' do
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{nodelist}
            )
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: node1\.test\.org\n\s*nodeid: 3}
            )
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: node2\.test\.org\n\s*nodeid: 11}
            )
          end
        end

        context 'with node names' do
          let(:params) do
            super().merge(
              quorum_members: ['192.168.0.1', '192.168.0.2'],
              quorum_members_names: ['node1.test.org', 'node2.test.org']
            )
          end

          it 'supports persistent node names' do
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{nodelist}
            )
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: 192\.168\.0\.1\n\s*nodeid: 1\n\s*name: node1\.test\.org}
            )
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: 192\.168\.0\.2\n\s*nodeid: 2\n\s*name: node2\.test\.org}
            )
          end
        end
      end

      context 'when quorum_members is set to an array with 3 items' do
        let(:params) do
          super().merge(
            quorum_members: ['node1.test.org', 'node2.test.org', 'node3.test.org'],
            votequorum_expected_votes: 3
          )
        end

        it 'does not configure two_nodes option' do
          is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is not set and votequorum_expected_votes is set' do
        let(:params) do
          super().merge(
            votequorum_expected_votes: 2
          )
        end

        it 'configures two_node' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is set to an array with 2 items and votequorum_expected_votes is set' do
        let(:params) do
          super().merge(
            quorum_members: ['node1.test.org', 'node2.test.org'],
            votequorum_expected_votes: 2
          )
        end

        it 'configures nodelist' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node1\.test\.org\n\s*nodeid: 1}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node2\.test\.org\n\s*nodeid: 2}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is an array of arrays' do
        let(:params) do
          super().merge(
            quorum_members: [
              ['172.31.10.1', '172.31.11.1', '172.31.12.1'],
              ['172.31.10.2', '172.31.11.2', '172.31.12.2'],
              ['172.31.10.3', '172.31.11.3', '172.31.12.3'],
              ['172.31.10.4', '172.31.11.4', '172.31.12.4']
            ]
          )
        end

        (1..4).each do |node_id|
          it "configures rings for host #{node_id} correctly" do
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: 172.31.10.#{node_id}\n\s*ring1_addr: 172.31.11.#{node_id}\n\s*ring2_addr: 172.31.12.#{node_id}\n\s*nodeid: #{node_id}}
            )
          end
        end

        it 'does not configure two_nodes option' do
          is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end

      context 'when quorum_members is an array of 2 arrays' do
        let(:params) do
          super().merge(
            quorum_members: [
              ['172.31.10.1', '172.31.11.1', '172.31.12.1'],
              ['172.31.10.2', '172.31.11.2', '172.31.12.2']
            ]
          )
        end

        (1..2).each do |node_id|
          it "configures rings for host #{node_id} correctly" do
            is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
              %r{ring0_addr: 172.31.10.#{node_id}\n\s*ring1_addr: 172.31.11.#{node_id}\n\s*ring2_addr: 172.31.12.#{node_id}\n\s*nodeid: #{node_id}}
            )
          end
        end

        it 'configures two_node' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end
      end
    end

    context 'when unicast is used' do
      let(:params) do
        super().merge(
          multicast_address: :undef,
          unicast_addresses: ['192.168.1.1', '192.168.1.2']
        )
      end

      context 'when set_quorum is true' do
        let(:params) do
          super().merge(
            set_votequorum: true,
            quorum_members: ['node1.test.org', 'node2.test.org']
          )
        end

        it 'configures votequorum' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node1\.test\.org\n\s*nodeid: 1}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node2\.test\.org\n\s*nodeid: 2}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{two_node: 1\n}
          )
        end

        it 'supports persistent node IDs' do
          params[:quorum_members_ids] = [3, 11]
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node1\.test\.org\n\s*nodeid: 3}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: node2\.test\.org\n\s*nodeid: 11}
          )
        end

        it 'supports persistent node names' do
          params[:quorum_members] = ['192.168.0.1', '192.168.0.2']
          params[:quorum_members_names] = ['node1.test.org', 'node2.test.org']
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: 192\.168\.0\.1\n\s*nodeid: 1\n\s*name: node1\.test\.org}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{ring0_addr: 192\.168\.0\.2\n\s*nodeid: 2\n\s*name: node2\.test\.org}
          )
        end
      end

      context 'with one ring' do
        let(:params) do
          super().merge(
            bind_address: '10.0.0.1',
            unicast_addresses: ['10.0.0.1', '10.0.0.2']
          )
        end

        it 'configures the ring properly' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{interface.*memberaddr: 10\.0\.0\.1.*memberaddr: 10\.0\.0\.2.*bindnetaddr: 10\.0\.0\.1.*ringnumber:\s+0}m
          )
        end
      end

      context 'with multiple rings' do
        let(:params) do
          super().merge(
            bind_address: ['10.0.0.1', '10.0.1.1'],
            unicast_addresses: [
              [
                '10.0.0.1',
                '10.0.1.1'
              ], [
                '10.0.0.2',
                '10.0.1.2'
              ]
            ]
          )
        end

        it 'configures the rings properly' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{interface.*memberaddr: 10\.0\.0\.1.*memberaddr: 10\.0\.0\.2.*bindnetaddr: 10\.0\.0\.1.*ringnumber:\s+0.*interface.*memberaddr: 10\.0\.1\.1.*memberaddr: 10\.0\.1\.2.*bindnetaddr: 10\.0\.1\.1.*ringnumber:\s+1}m
          )
        end
      end
    end

    context 'when cluster_name is not set' do
      it do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{cluster_name:}
        )
      end
    end

    context 'when cluster_name is set' do
      let(:params) do
        super().merge(
          cluster_name: 'hacell'
        )
      end

      it 'configures cluster_name' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{cluster_name:\s*hacell$}
        )
      end
    end

    context 'when authkey is a string' do
      let(:params) do
        super().merge(
          authkey_source: 'string',
          authkey: 'bXlzZWNyZXRrZXkK' # 'mysecretkey' in base64
        )
      end

      it 'deploys authkey file' do
        is_expected.to contain_file('/etc/corosync/authkey').with(
          content: "mysecretkey\n",
          before: ['File[/etc/corosync/corosync.conf]']
        )
      end
    end

    context 'when authkey is a file' do
      let(:params) do
        super().merge(
          authkey: '/etc/pki/tls/private/corosync.key'
        )
      end

      it 'deploys authkey file' do
        is_expected.to contain_file('/etc/corosync/authkey').with(
          source: '/etc/pki/tls/private/corosync.key',
          before: ['File[/etc/corosync/corosync.conf]']
        )
      end
    end

    context 'when multicast_address, unicast_addresses and cluster_name are not set' do
      let(:params) do
        super().merge(
          multicast_address: :undef
        )
      end

      it 'raises error' do
        is_expected.to raise_error(
          Puppet::Error,
          %r{You must provide a value for multicast_address, unicast_address or cluster_name\.}
        )
      end
    end

    context 'when only cluster_name is set' do
      let(:params) do
        super().merge(
          multicast_address: :undef,
          cluster_name: 'mycluster'
        )
      end

      it 'does not configure multicast' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{broadcast}
        )
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{mcastaddr}
        )
      end
    end

    context 'when log_timestamp is not set' do
      it 'does not set timestamp' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{timestamp}
        )
      end
    end

    context 'when log_timestamp is false' do
      let(:params) do
        super().merge(
          log_timestamp: false
        )
      end

      it 'does not set timestamp' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{timestamp}
        )
      end
    end

    context 'when log_timestamp is set' do
      let(:params) do
        super().merge(
          log_timestamp: true
        )
      end

      it 'does set timestamp' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{timestamp.*on}
        )
      end
    end

    context 'when log_file is not set' do
      it 'does set to_logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_logfile.*yes}
        )
      end

      it 'does not set logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{^\s*logfile}
        )
      end
    end

    context 'with undefined watchdog_device' do
      it 'does not configure watchdog_device resource' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{watchdog_device:}
        )
      end
    end

    context 'with defined watchdog_device' do
      let(:params) { super().merge(watchdog_device: 'off') }

      it 'configures watchdog_device resource' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{watchdog_device: off}
        )
      end
    end

    context 'when log_file and log_file_name are set' do
      let(:params) do
        super().merge(
          log_file: true,
          log_file_name: '/var/log/corosync/corosync.log'
        )
      end

      it 'does set to_logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_logfile.*yes}
        )
      end

      it 'does set logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{logfile.*/var/log/corosync/corosync\.log}
        )
      end
    end

    context 'when log_file is disabled' do
      let(:params) do
        super().merge(
          log_file: false
        )
      end

      it 'does not set to_logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_logfile.*no}
        )
      end

      it 'does not set logfile' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
          %r{^\s*logfile}
        )
      end
    end

    {
      'threads' => 10,
      'rrp_mode' => 'none',
      'netmtu' => 1500,
      'token' => 3000,
      'vsftype' => 'none',
      'token_retransmits_before_loss_const' => 10,
      'join' => 50,
      'compatibility' => 'whitetank'
    }.each do |optional_parameter, possible_value|
      context "when #{optional_parameter} is not set" do
        it 'is not in corosync.conf' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').without_content(
            %r{#{optional_parameter}}
          )
        end
      end

      context "when #{optional_parameter} is set" do
        let(:params) do
          super().merge(
            optional_parameter => possible_value
          )
        end

        it 'is set in corosync.conf' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{#{optional_parameter}:\s*#{possible_value}\n}
          )
        end
      end
    end

    %i[corosync pacemaker].each do |package|
      context "install package #{package} with default version" do
        let(:params) { super().merge("package_#{package}" => true) }

        it "does install #{package}" do
          is_expected.to contain_package(package).with(
            ensure: 'present'
          )
        end
      end

      context "install package #{package} with custom version" do
        let(:params) do
          super().merge(
            "package_#{package}" => true,
            "ensure_#{package}" => '1.1.1'
          )
        end

        it "does install #{package} with version 1.1.1" do
          is_expected.to contain_package(package).with(
            ensure: '1.1.1'
          )
        end
      end

      context "do not install #{package}" do
        let(:params) { super().merge("package_#{package}" => false) }

        it "does not install #{package}" do
          is_expected.not_to contain_package(package)
        end
      end
    end

    context 'when set_votequorum is true and quorum_members is not set' do
      let(:params) do
        super().merge(
          set_votequorum: true,
          quorum_members: []
        )
      end

      context 'when multicast_address is set' do
        let(:params) do
          super().merge(
            multicast_address: '10.0.0.1',
            cluster_name: :undef
          )
        end

        it 'does not contain nodelist' do
          is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
        end
      end

      context 'when cluster_name is set' do
        let(:params) do
          super().merge(
            multicast_address: [],
            cluster_name: 'mycluster'
          )
        end

        it 'does not contain nodelist' do
          is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{nodelist}
          )
        end
      end

      context 'when multicast_address and cluster_name are not set' do
        let(:params) do
          super().merge(
            multicast_address: [],
            cluster_name: :undef
          )
        end

        it 'raises error' do
          is_expected.to raise_error(
            Puppet::Error,
            %r{set_votequorum is true, so you must set either quorum_members, or one of multicast_address or cluster_name.}
          )
        end
      end
    end

    context 'when configuring defaults for logging' do
      it 'configures stderr, syslog priority, func names' do
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{to_stderr:       yes}
        )
        is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{syslog_priority: info}
        )
        is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
          %r{function_name:   on}
        )
      end
    end
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      auth_command = if corosync_stack(os_facts)[:provider] == 'pcs'
                       if Gem::Version.new(corosync_stack(os_facts)[:pcs_version]) < Gem::Version.new('0.10.0')
                         'cluster auth'
                       else
                         'host auth'
                       end
                     else
                       'cluster auth'
                     end
      cluster_name_arg = if corosync_stack(os_facts)[:provider] == 'pcs'
                           if Gem::Version.new(corosync_stack(os_facts)[:pcs_version]) < Gem::Version.new('0.10.0')
                             '--name'
                           else
                             ''
                           end
                         else
                           '--name'
                         end
      provider_package = case corosync_stack(os_facts)[:provider]
                         when 'pcs'
                           'pcs'
                         else
                           'crmsh'
                         end

      it 'has the correct pcs version' do
        is_expected.to contain_class('corosync').with(
          'pcs_version' => corosync_stack(os_facts)[:pcs_version]
        )
      end

      context 'without secauth' do
        let(:params) do
          super().merge(
            enable_secauth: false
          )
        end

        it { is_expected.to compile.with_all_deps }

        it 'disables secauth with corsync 2.x syntax' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{crypto_hash:\s+none}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{crypto_cipher:\s+none}
          )
        end
      end

      context 'with secauth' do
        let(:params) do
          super().merge(
            enable_secauth: true
          )
        end

        it { is_expected.to compile.with_all_deps }

        it 'enables secauth with corsync 2.x syntax' do
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{crypto_hash:\s+sha1}
          )
          is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
            %r{crypto_cipher:\s+aes256}
          )
        end
      end

      it_configures 'corosync'

      # Check default package installations per platform
      case os_facts[:os]['family']
      when 'RedHat'
        it 'installs fence-agents-all' do
          is_expected.to contain_package('fence-agents-all')
        end
      end

      it 'installs the provider package' do
        is_expected.to contain_package(provider_package).with(
          ensure: 'present',
          install_options: nil
        )
      end

      it 'does manage the pacemaker service' do
        is_expected.to contain_service('pacemaker').with(
          ensure: 'running'
        )
      end

      # Tests for pcsd_auth management
      if corosync_stack(os_facts)[:provider] == 'pcs'
        context 'when mananging pcsd authorization' do
          let(:params) do
            super().merge(
              manage_pcsd_service: true,
              manage_pcsd_auth: true,
              sensitive_hacluster_hash: RSpec::Puppet::RawString.new("Sensitive('some-secret-hash')"),
              sensitive_hacluster_password: RSpec::Puppet::RawString.new("Sensitive('some-secret-password')"),
              quorum_members: [
                'node1.test.org',
                'node2.test.org',
                'node3.test.org'
              ]
            )
          end
          let(:node) { 'node1.test.org' }

          [
            [:sensitive_hacluster_password, %r{The hacluster password and hash must be provided to authorize nodes via pcsd}],
            [:sensitive_hacluster_hash, %r{The hacluster password and hash must be provided to authorize nodes via pcsd}]
          ].each do |param, expected|
            context "without #{param}" do
              let(:params) do
                result = super()
                result.delete(param)
                result
              end

              it { is_expected.to compile.and_raise_error(expected) }
            end
          end

          context 'and not the first node' do
            let(:node) { 'node2.test.org' }

            it 'does not perform the auth' do
              is_expected.not_to contain_exec('authorize_members')
            end
          end

          it 'configures the hacluster user and haclient group' do
            is_expected.to contain_group('haclient').that_requires("Package[#{provider_package}]")
            is_expected.to contain_user('hacluster').with(
              ensure: 'present',
              gid: 'haclient',
              password: 'some-secret-hash'
            )
          end

          context 'with a password' do
            let(:params) do
              super().merge(
                sensitive_hacluster_password: RSpec::Puppet::RawString.new("Sensitive('some-secret-sauce')"),
                sensitive_hacluster_hash: RSpec::Puppet::RawString.new("Sensitive('some-secret-hash')")
              )
            end

            it 'authorizes all nodes' do
              is_expected.to contain_exec('authorize_members').with(
                command: "pcs #{auth_command} node1.test.org node2.test.org node3.test.org -u hacluster -p some-secret-sauce",
                path: '/sbin:/bin:/usr/sbin:/usr/bin',
                require: [
                  'Service[pcsd]',
                  'User[hacluster]'
                ]
              )
            end
          end

          context 'using an ip baseid node list' do
            let(:params) do
              super().merge(
                sensitive_hacluster_password: RSpec::Puppet::RawString.new("Sensitive('some-secret-sauce')"),
                sensitive_hacluster_hash: RSpec::Puppet::RawString.new("Sensitive('some-secret-hash')"),
                quorum_members: [
                  '192.168.0.10',
                  '192.168.0.12',
                  '192.168.0.13'
                ],
                quorum_members_names: [
                  'node1.test.org',
                  'node2.test.org',
                  'node3.test.org'
                ]
              )
            end

            let(:facts) { override_facts(super(), networking: { ip: '192.168.0.10' }) }

            it 'match ip and auth nodes by member names' do
              is_expected.to contain_exec('authorize_members').with(
                command: "pcs #{auth_command} 192.168.0.10 192.168.0.12 192.168.0.13 -u hacluster -p some-secret-sauce",
                path: '/sbin:/bin:/usr/sbin:/usr/bin',
                require: [
                  'Service[pcsd]',
                  'User[hacluster]'
                ]
              )
            end

            context 'where the auth-node IP is not the default IP' do
              let(:facts) do
                override_facts(super(),
                               networking: {
                                 ip: '10.0.0.48',
                                 interfaces: {
                                   eth0: {
                                     ip: '10.0.0.48'
                                   },
                                   eth1: {
                                     ip: '192.168.0.10'
                                   }
                                 }
                               })
              end

              it 'still detects that this is the auth-node' do
                is_expected.to contain_exec('authorize_members')
              end
            end
          end
        end
      end

      # Corosync qnet device is enabled
      if corosync_stack(os_facts)[:provider] == 'pcs'
        context 'when quorum device is configured' do
          let(:params) do
            super().merge(
              set_votequorum: true,
              manage_pcsd_service: true,
              manage_pcsd_auth: true,
              sensitive_hacluster_password: RSpec::Puppet::RawString.new("Sensitive('some-secret-sauce')"),
              sensitive_hacluster_hash: RSpec::Puppet::RawString.new("Sensitive('some-secret-hash')"),
              quorum_members: [
                'node1.test.org',
                'node2.test.org',
                'node3.test.org'
              ],
              cluster_name: 'cluster_test',
              manage_quorum_device: true,
              quorum_device_host: 'quorum1.test.org',
              quorum_device_algorithm: 'ffsplit',
              sensitive_quorum_device_password: RSpec::Puppet::RawString.new("Sensitive('quorum-secret-password')")
            )
          end
          let(:node) { 'node1.test.org' }

          context 'without the proper arguments' do
            [
              [:quorum_device_host, %r{The quorum device host must be specified!}],
              [:sensitive_quorum_device_password, %r{The password for the hacluster user on the quorum device node is mandatory!}],
              [:cluster_name, %r{A cluster name must be specified when a quorm device is configured!}]
            ].each do |param, expected|
              context "without #{param}" do
                let(:params) do
                  result = super()
                  result.delete(param)
                  result
                end

                it { is_expected.to compile.and_raise_error(expected) }
              end
            end
          end

          context 'and a cluster member is specified as the quorum device' do
            let(:params) do
              super().merge(
                quorum_device_host: 'node3.test.org'
              )
            end

            it 'fails to deploy' do
              is_expected.to raise_error(
                Puppet::Error,
                %r{Quorum device host cannot also be a member of the cluster!}
              )
            end
          end

          context 'without managing pcsd auth' do
            let(:params) do
              result = super()
              result.delete(:manage_pcsd_auth)
              result
            end

            it 'does not contain the quorum device config in corosync.conf' do
              is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
                %r!quorum {
  provider: corosync_votequorum
}$!m
              )
            end

            it 'does not install the pcs quorum device package' do
              is_expected.not_to contain_package('corosync-qdevice')
            end

            it 'does not attempt to authorize or configure the quorum node' do
              is_expected.not_to contain_exec('authorized_qdevice')
              is_expected.not_to contain_exec('pcs_cluster_add_qdevice')
            end
          end

          context 'and not the first node' do
            let(:node) { 'node2.test.org' }

            it 'contains the quorum configuration' do
              is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
                %r!quorum {
  provider: corosync_votequorum
  device {
    model: net
    votes: 1

    net {
      algorithm: ffsplit
      host:      quorum1[.]test[.]org
    }
  }
}!m
              )
            end

            it 'installs the quorum device package' do
              is_expected.to contain_package('corosync-qdevice').with(
                ensure: 'present'
              )
            end

            it 'configures the qdevice service' do
              is_expected.to contain_service('corosync-qdevice').with(
                ensure: 'running',
                enable: 'true',
                require: 'Package[corosync-qdevice]',
                subscribe: 'Service[corosync]'
              )
            end

            it 'does not authorize or add the quorum device' do
              is_expected.not_to contain_exec('authorize_qdevice')
              is_expected.not_to contain_exec('pcs_cluster_add_qdevice')
            end
          end

          context 'with all parameters' do
            it 'installs the quorum device package' do
              is_expected.to contain_package('corosync-qdevice').with(
                ensure: 'present'
              )
            end

            it 'configures the qdevice service' do
              is_expected.to contain_service('corosync-qdevice').with(
                ensure: 'running',
                enable: 'true',
                require: 'Package[corosync-qdevice]',
                subscribe: 'Service[corosync]'
              )
            end

            case corosync_stack(os_facts)[:provider]
            when 'pcs'
              it 'configures a temporary cluster if corosync.conf is missing' do
                is_expected.to contain_exec('pcs_cluster_temporary').with(
                  command: "pcs cluster setup --force #{cluster_name_arg} cluster_test node1.test.org node2.test.org node3.test.org",
                  path: '/sbin:/bin:/usr/sbin:/usr/bin',
                  onlyif: 'test ! -f /etc/corosync/corosync.conf',
                  require: 'Exec[authorize_members]'
                )
              end

              it 'authorizes and adds the quorum device' do
                is_expected.to contain_exec('authorize_qdevice').with(
                  command: "pcs #{auth_command} quorum1.test.org -u hacluster -p quorum-secret-password",
                  path: '/sbin:/bin:/usr/sbin:/usr/bin',
                  onlyif: 'test 0 -ne $(grep quorum1.test.org /var/lib/pcsd/tokens >/dev/null 2>&1; echo $?)',
                  require: [
                    'Package[corosync-qdevice]',
                    'Exec[authorize_members]',
                    'Exec[pcs_cluster_temporary]'
                  ]
                )

                is_expected.to contain_exec('pcs_cluster_add_qdevice').with(
                  command: 'pcs quorum device add model net host=quorum1.test.org algorithm=ffsplit',
                  path: '/sbin:/bin:/usr/sbin:/usr/bin',
                  onlyif: [
                    'test 0 -ne $(pcs quorum config | grep "host:" >/dev/null 2>&1; echo $?)'
                  ],
                  require: 'Exec[authorize_qdevice]'
                )
              end

              it 'contains the quorum configuration' do
                is_expected.to contain_file('/etc/corosync/corosync.conf').with_content(
                  %r!quorum {
  provider: corosync_votequorum
  device {
    model: net
    votes: 1

    net {
      algorithm: ffsplit
      host:      quorum1[.]test[.]org
    }
  }
}!m
                )
              end
            end
          end

          context 'with two nodes' do
            let(:params) do
              super().merge(
                quorum_members: [
                  'node1.test.org',
                  'node2.test.org'
                ]
              )
            end

            it 'does not configure two node' do
              is_expected.not_to contain_file('/etc/corosync/corosync.conf').with_content(
                %r{two_node: 1\n}
              )
            end
            # else - to implement
          end
        end
      end
    end
  end
end
