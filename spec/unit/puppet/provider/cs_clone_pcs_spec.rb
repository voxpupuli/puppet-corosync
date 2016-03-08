require 'spec_helper'
require 'spec_helper_corosync'

describe Puppet::Type.type(:cs_clone).provider(:pcs) do
  before do
    described_class.stubs(:command).with(:pcs).returns 'pcs'
  end

  context 'when getting instances' do
    let :instances do
      test_cib = <<-EOS
        <cib>
        <configuration>
          <resources>
            <clone id="p_keystone-clone">
              <primitive class="systemd" id="p_keystone" type="openstack-keystone">
                <meta_attributes id="p_keystone-meta_attributes"/>
                <operations/>
              </primitive>
              <meta_attributes id="p_keystone-clone-meta"/>
            </clone>
          </resources>
        </configuration>
        </cib>
      EOS

      described_class.expects(:block_until_ready).returns(nil)
      if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '3.4') == -1
        Puppet::Util::SUIDManager.expects(:run_and_capture).with(%w(pcs cluster cib)).at_least_once.returns([test_cib, 0])
      else
        Puppet::Util::Execution.expects(:execute).with(%w(pcs cluster cib), :failonfail => true, :combine => true).at_least_once.returns(
          Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
        )
      end
      # rubocop:disable Lint/UselessAssignment
      instances = described_class.instances
      # rubocop:enable Lint/UselessAssignment
    end

    it 'should have an instance for each <clone>' do
      expect(instances.count).to eq(1)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "is a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "is named by the <primitive>'s id attribute" do
        expect(instance.name).to eq('p_keystone-clone')
      end
    end
  end

  context 'when flushing' do
    let :resource do
      Puppet::Type.type(:cs_clone).new(
        :name      => 'p_keystone',
        :provider  => :pcs,
        :primitive => 'p_keystone',
        :ensure    => :present)
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    it 'creates clone' do
      expect_commands(/pcs resource clone p_keystone/)
      instance.flush
    end

    it 'sets max clones' do
      instance.clone_max = 3
      expect_commands(/clone-max=3/)
      instance.flush
    end

    it 'sets max node clones' do
      instance.clone_node_max = 3
      expect_commands(/clone-node-max=3/)
      instance.flush
    end

    it 'sets notify_clones' do
      instance.notify_clones = :true
      expect_commands(/notify=true/)
      instance.flush
    end

    it 'sets globally unique' do
      instance.globally_unique = :true
      expect_commands(/globally-unique=true/)
      instance.flush
    end

    it 'sets ordered' do
      instance.ordered = :true
      expect_commands(/ordered=true/)
      instance.flush
    end

    it 'sets interleave' do
      instance.interleave = :true
      expect_commands(/interleave=true/)
      instance.flush
    end
  end
end
