require 'flipper/adapters/dual_write'
require 'flipper/adapters/operation_logger'
require 'active_support/notifications'

RSpec.describe Flipper::Adapters::DualWrite do
  let(:local_adapter) do
    Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new
  end
  let(:remote_adapter) do
    Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new
  end
  let(:local) { Flipper.new(local_adapter) }
  let(:remote) { Flipper.new(remote_adapter) }
  let(:sync) { Flipper.new(subject) }

  subject do
    described_class.new(local_adapter, remote_adapter)
  end

  it_should_behave_like 'a flipper adapter'

  it 'only uses local for #features' do
    subject.features
  end

  it 'only uses local for #get' do
    subject.get sync[:search]
  end

  it 'only uses local for #get_multi' do
    subject.get_multi [sync[:search]]
  end

  it 'only uses local for #get_all' do
    subject.get_all
  end

  it 'updates remote and local for #add' do
    subject.add sync[:search]
    expect(remote_adapter.count(:add)).to be(1)
    expect(local_adapter.count(:add)).to be(1)
  end

  it 'updates remote and local for #remove' do
    subject.remove sync[:search]
    expect(remote_adapter.count(:remove)).to be(1)
    expect(local_adapter.count(:remove)).to be(1)
  end

  it 'updates remote and local for #clear' do
    subject.clear sync[:search]
    expect(remote_adapter.count(:clear)).to be(1)
    expect(local_adapter.count(:clear)).to be(1)
  end

  it 'updates remote and local for #enable' do
    feature = sync[:search]
    subject.enable feature, feature.gate(:boolean), local.boolean
    expect(remote_adapter.count(:enable)).to be(1)
    expect(local_adapter.count(:enable)).to be(1)
  end

  it 'updates remote and local for #disable' do
    feature = sync[:search]
    subject.disable feature, feature.gate(:boolean), local.boolean(false)
    expect(remote_adapter.count(:disable)).to be(1)
    expect(local_adapter.count(:disable)).to be(1)
  end
end
