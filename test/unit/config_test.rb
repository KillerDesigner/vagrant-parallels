require_relative 'base'

require VagrantPlugins::Parallels.source_root.join('lib/vagrant-parallels/config')

describe VagrantPlugins::Parallels::Config do
  let(:machine) { double('machine') }

  def assert_invalid
    errors = subject.validate(machine)
    if !errors.values.any? { |v| !v.empty? }
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.values.all? { |v| v.empty? }
      raise "Errors: #{errors.inspect}"
    end
  end

  def valid_defaults
    subject.image = 'foo'
  end

  before do
    vm_config = double('vm_config')
    vm_config.stub(networks: [])
    config = double('config')
    config.stub(vm: vm_config)
    machine.stub(config: config)
  end

  its 'valid by default' do
    subject.finalize!
    assert_valid
  end

  context 'defaults' do
    before { subject.finalize! }

    it { expect(subject.check_guest_additions).to be_true }
    it { expect(subject.name).to be_nil }
    it { expect(subject.functional_psf).to be_true }
    it { expect(subject.optimize_power_consumption).to be_true }

    it 'should have one Shared adapter' do
      expect(subject.network_adapters).to eql({
        0 => [:shared, {}],
      })
    end
  end

  describe '#merge' do
    let(:one) { described_class.new }
    let(:two) { described_class.new }

    subject { one.merge(two) }

    it 'merges the customizations' do
      one.customize ['foo']
      two.customize ['bar']

      expect(subject.customizations).to eq([
        ['pre-boot', ['foo']],
        ['pre-boot', ['bar']]])
    end
  end

  describe 'memory=' do
    it 'configures memory size (in Mb)' do
      subject.memory=(1024)
      expect(subject.customizations).to include(['pre-boot', ['set', :id, '--memsize', '1024']])
    end
  end

  describe 'cpus=' do
    it 'configures count of cpus' do
      subject.cpus=('4')
      expect(subject.customizations).to include(['pre-boot', ['set', :id, '--cpus', 4]])
    end
  end

  describe '#network_adapter' do
    it 'configures additional adapters' do
      subject.network_adapter(2, :bridged, auto_config: true)
      expect(subject.network_adapters[2]).to eql(
        [:bridged, auto_config: true])
    end
  end
end
