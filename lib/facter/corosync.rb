require 'facter'
require 'rexml/document'


if Facter.value(:facterversion).split('.').first == '2'
  Facter.add(:corosync_resource_status) do
    confine :kernel => :linux
    confine do
      Facter::Core::Execution.which('crm_mon')
    end

    setcode do
      command     = '/usr/sbin/crm_mon -r -1 -X'
      command_xml = Facter::Core::Execution.exec(command)
      hash        = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
      fqdn        = Facter.value(:fqdn)

      if ! command_xml.nil?
        xmldoc = REXML::Document.new(command_xml)
        xmldoc.elements.each("crm_mon/resources/clone") do |e|
          ms_resource_id = e.attributes["id"]
          role           = nil
          resource_id    = nil

          e.each_recursive do |ce|
            if ce.attributes['role']
              resource_id = ce.attributes['id']
              role = ce.attributes['role']
            elsif ce.attributes['name']
              node_name = ce.attributes['name']
            end

            if role and resource_id and node_name
              if node_name == fqdn
                hash[ms_resource_id][resource_id][role] = true
              else
                hash[ms_resource_id][resource_id][role] = false
              end
            end
          end
        end
      end

      # Return the structured hash
      hash

    end
  end
end
