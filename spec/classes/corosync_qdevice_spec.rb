# frozen_string_literal: true

require 'spec_helper'

describe 'corosync::qdevice' do
  let(:params) do
    {
      sensitive_hacluster_hash: RSpec::Puppet::RawString.new("Sensitive('some-secret-hash')")
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      provider_package = case corosync_stack(os_facts)[:provider]
                         when 'pcs'
                           'pcs'
                         else
                           'crmsh'
                         end

      case corosync_stack(os_facts)[:provider]
      when 'pcs'
        context 'standard quorum node install' do
          [provider_package, 'corosync-qnetd'].each do |package|
            it "does install #{package}" do
              is_expected.to contain_package(package).with(
                ensure: 'present'
              )
            end
          end

          it 'creates the cluster group' do
            is_expected.to contain_group('haclient').that_requires("Package[#{provider_package}]")
          end

          it 'sets the hacluster password' do
            is_expected.to contain_user('hacluster').with(
              ensure: 'present',
              password: 'some-secret-hash',
              gid: 'haclient'
            )
          end

          it 'configures the pcsd service' do
            is_expected.to contain_service('pcsd').with(
              ensure: 'running',
              enable: 'true',
              require: [
                'Package[pcs]',
                'Package[corosync-qnetd]'
              ]
            )
          end

          it 'configures the net quorum device' do
            is_expected.to contain_exec('pcs qdevice setup model net --enable --start').with(
              path: '/sbin:/bin:/usr/sbin:/usr/bin',
              onlyif: [
                'test ! -f /etc/corosync/qnetd/nssdb/qnetd-cacert.crt'
              ],
              require: 'Service[pcsd]'
            )
          end

          it 'makes sure the net quorum device is started' do
            is_expected.to contain_exec('pcs qdevice start net').with(
              path: '/sbin:/bin:/usr/sbin:/usr/bin',
              onlyif: [
                'test -f /etc/corosync/qnetd/nssdb/qnetd-cacert.crt',
                'test 0 -ne $(pcs qdevice status net >/dev/null 2>&1; echo $?)'
              ],
              require: [
                'Package[pcs]',
                'Package[corosync-qnetd]'
              ]
            )
          end
        end
      when 'crm'
        it 'shoud fail because we do not have qdevice support for crm' do
          is_expected.to compile.and_raise_error(%r{qdevice not supported by this module with provider crm})
        end
      else
        raise('Unknown provider!')
      end
    end
  end
end
