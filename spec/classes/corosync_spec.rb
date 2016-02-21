require 'spec_helper'

describe 'corosync' do
  let :params do
    { :set_votequorum => false,
      :multicast_address => '239.1.1.2' }
  end

  shared_examples_for 'corosync' do
    it { is_expected.to compile }

    context 'when set_quorum is true and quorum_members are set' do
      before :each do
        params.merge!(
          :set_votequorum => true,
          :quorum_members => ['node1.test.org', 'node2.test.org']
        )
      end

      it 'configures votequorum' do
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /nodelist/
        )
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /ring0_addr\: node1\.test\.org\n\s*nodeid: 1/
        )
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /ring0_addr\: node2\.test\.org\n\s*nodeid: 2/
        )
      end

      it 'supports persistent node IDs' do
        params[:quorum_members_ids] = [3, 11]
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /nodelist/
        )
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /ring0_addr\: node1\.test\.org\n\s*nodeid: 3/
        )
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /ring0_addr\: node2\.test\.org\n\s*nodeid: 11/
        )
      end
    end

    context 'when set_quorum is true and unicast is used' do
      before :each do
        params.merge!(
          :set_votequorum => true,
          :quorum_members => ['node1.test.org', 'node2.test.org'],
          :multicast_address => 'UNSET',
          :unicast_addresses => ['192.168.1.1', '192.168.1.2']
        )
      end

      it 'configures votequorum' do
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /nodelist/
        )
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /ring0_addr\: node1\.test\.org/
        )
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /ring0_addr\: node2\.test\.org/
        )
      end
    end

    context 'when cluster_name is not set' do
      it { should contain_file('/etc/corosync/corosync.conf').without_content(
        /cluster_name\:/
        )
      }
    end

    context 'when cluster_name is set' do
      before :each do
        params.merge!(
          :cluster_name => 'hacell'
        )
      end

      it 'configures cluster_name' do
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /cluster_name\:\s*hacell$/
        )
      end
    end

    [:package_corosync, :package_pacemaker, :version_corosync, :version_pacemaker].each { |package_param|
      context "new-style package parameter $#{package_param} mixed with deprecated $packages parameter" do
        before :each do
          params.merge!(
            package_param => true, # value does not really matter here: these
            # two params must not both be defined
            # at the same time.
            :packages => %w(corosync pacemaker)
          )
        end

        it 'raises error' do
          should raise_error(
            Puppet::Error,
            /\$corosync::#{package_param} and \$corosync::packages must not be mixed!/
          )
        end
      end
    }

    [:corosync, :pacemaker].each { |package|
      context "install package #{package} with default version" do
        before :each do
          params.merge!("package_#{package}" => true)
        end

        it "does install #{package}" do
          should contain_package(package).with(
            :ensure => 'present'
          )
        end
      end

      context "install package #{package} with custom version" do
        before :each do
          params.merge!(
            "package_#{package}" => true,
            "version_#{package}" => '1.1.1'
                       )
        end

        it "does install #{package} with version 1.1.1" do
          should contain_package(package).with(
            :ensure => '1.1.1'
          )
        end
      end

      context "do not install #{package}" do
        before :each do
          params.merge!("package_#{package}" => false)
        end

        it "does not install #{package}" do
          should_not contain_package(package)
        end
      end
    }

    context 'when set_quorum is true and quorum_members are not set' do
      before :each do
        params.merge!(
          :set_votequorum => true,
          :quorum_members => false
        )
      end

      it 'raises error' do
        should raise_error(
          Puppet::Error,
          /set_votequorum is true, but no quorum_members have been passed./
        )
      end
    end

    context 'when configuring defaults for logging' do
      it 'should configure stderr, syslog priority, func names' do
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /to_stderr:       yes/)
        should contain_file('/etc/corosync/corosync.conf').with_content(
          /syslog_priority: info/)
        should_not contain_file('/etc/corosync/corosync.conf').with_content(
          /function_name:   on/)
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
        :processorcount  => '3',
        :ipaddress       => '127.0.0.1' }
    end

    it_configures 'corosync'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily       => 'RedHat',
        :processorcount => '3',
        :ipaddress      => '127.0.0.1' }
    end

    it_configures 'corosync'
  end
end
