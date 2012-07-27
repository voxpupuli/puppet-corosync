module Puppet
  newtype(:cs_shadow) do
    newproperty(:cib) do
      def sync
        provider.create(self.should)
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
  end
end
