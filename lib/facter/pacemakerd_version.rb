Facter.add(:pacemakerd_version) do
  setcode do

    pacemakerd_version_string = Facter::Util::Resolution.exec('pacemakerd --version 2>&1')

    unless pacemakerd_version_string.nil?
      match = %r{^Pacemaker (\d+.\d+(.\d+)?)}.match(pacemakerd_version_string)
      match[1] unless match.nil?
    end
  end
end
