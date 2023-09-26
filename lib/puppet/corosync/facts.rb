require 'facter'
require 'English'

# Module containing code for constructing facts about the pacemaker code
# present on this system
#
# Note that this structure is primarily a mechanism to allow rspec based
# testing of the fact code.
module Puppet::Corosync
  # Contains the control code needed to actually add facts. Note that the fact
  # collection code is primarily located in the inner module `HostData`.
  module Facts
    # Calls the Facter DSL and dynamically adds the local facts.
    #
    # This helps facilitate testing of the ruby code presented by this module
    #
    # @return [NilClass]
    def self.install
      Puppet::Corosync::Facts::HostData.initialize

      Facter.add(:corosync, type: :aggregate) do
        chunk(:pcs_version_full) do
          { pcs_version_full: Puppet::Corosync::Facts::HostData.pcs_version_full }
        end
        chunk(:pcs_version_release) do
          { pcs_version_release: Puppet::Corosync::Facts::HostData.pcs_version_release }
        end
        chunk(:pcs_version_major) do
          { pcs_version_major: Puppet::Corosync::Facts::HostData.pcs_version_major }
        end
        chunk(:pcs_version_minor) do
          { pcs_version_minor: Puppet::Corosync::Facts::HostData.pcs_version_minor }
        end
      end
    end

    # Honestly, I shamelessly stole this structure from the puppet-jenkins module.
    # This component contains all of the actual code generating fact data for a
    # given host.
    module HostData
      PCS_BIN = '/sbin/pcs'.freeze

      @attributes = {
        pcs_version_full: '',
        pcs_version_release: '',
        pcs_version_major: '',
        pcs_version_minor: ''
      }

      def self.initialize
        # Do nothing if the file doesn't exist
        if File.exist?(PCS_BIN)
          cmd = [
            PCS_BIN,
            '--version'
          ]
          result, = _run_command(cmd)
          version_string = result[:raw]
        else
          version_string = ''
        end

        pcs_version = check_pcs_version(version_string)
        @attributes[:pcs_version_full] = pcs_version[:full]
        @attributes[:pcs_version_release] = pcs_version[:release]
        @attributes[:pcs_version_major] = pcs_version[:major]
        @attributes[:pcs_version_minor] = pcs_version[:minor]

        # Create the getter methods
        @attributes.each do |attr, _value|
          define_singleton_method(attr) { @attributes[attr] }
        end
      end

      # Retrieve the locally installed version of PCS on this node
      def self.check_pcs_version(version_string)
        if %r{(?<release>\d+)[.](?<major>\d+)[.](?<minor>\d+)} =~ version_string
          {
            full: version_string,
            release: release,
            major: major,
            minor: minor
          }
        else
          {
            full: version_string,
            release: nil,
            major: nil,
            minor: nil
          }
        end
      end

      # Executes the provided command with some sane defaults
      def self._run_command(cmd,
                            failonfail = true,
                            custom_environment = { combine: true })
        # TODO: Potentially add some handling for when failonfail is false
        raw = Puppet::Util::Execution.execute(
          cmd,
          { failonfail: failonfail }.merge(custom_environment)
        )
        status = raw.exitstatus
        { raw: raw, status: status } if status.zero? || failonfail == false
      end
    end
  end
end
