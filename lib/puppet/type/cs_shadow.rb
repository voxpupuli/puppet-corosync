module Puppet
  newtype(:cs_shadow) do
    newproperty(:cib) do
      def sync
        provider.sync(self.should)
      end

      def retrieve
        :absent
      end

      def insync?(is)
        false
      end

      defaultto { @resource[:name] }
    end

    newparam(:name) do
      isnamevar
    end

    def generate
      options = { :name => @title }
      [ Puppet::Type.type(:cs_commit).new(options) ]
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end
