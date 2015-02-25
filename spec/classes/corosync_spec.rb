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
          { :set_votequorum => true,
            :quorum_members => ['node1.test.org', 'node2.test.org'] }
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

    context 'when set_quorum is true and unicast is used' do
      before :each do
        params.merge!(
          { :set_votequorum => true,
            :quorum_members => ['node1.test.org', 'node2.test.org'],
            :multicast_address => 'UNSET',
            :unicast_addresses => ['192.168.1.1', '192.168.1.2'], }
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

    context 'when set_quorum is true and quorum_members are not set' do
      before :each do
        params.merge!(
          { :set_votequorum => true,
            :quorum_members => false }
        )
      end

      it 'raises error' do
        should raise_error(
            Puppet::Error,
            /set_votequorum is true, but no quorum_members have been passed./
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily       => 'Debian',
        :processorcount => '3',
        :ipaddress      => '127.0.0.1' }
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
