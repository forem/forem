require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Adapters::OperationLogger do
  let(:operations) { [] }
  let(:adapter)    { Flipper::Adapters::Memory.new }
  let(:flipper)    { Flipper.new(adapter) }

  subject { described_class.new(adapter, operations) }

  it_should_behave_like 'a flipper adapter'

  it 'shows itself when inspect' do
    subject.features
    output = subject.inspect
    expect(output).to match(/OperationLogger/)
    expect(output).to match(/operation_logger/)
    expect(output).to match(/@type=:features/)
    expect(output).to match(/@adapter=#<Flipper::Adapters::Memory/)
  end

  it 'forwards missing methods to underlying adapter' do
    adapter = Class.new do
      def foo
        :foo
      end
    end.new
    operation_logger = described_class.new(adapter)
    expect(operation_logger.foo).to eq(:foo)
  end

  describe '#get' do
    before do
      @feature = flipper[:stats]
      @result = subject.get(@feature)
    end

    it 'logs operation' do
      expect(subject.count(:get)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.get(@feature))
    end
  end

  describe '#enable' do
    before do
      @feature = flipper[:stats]
      @gate = @feature.gate(:boolean)
      @thing = flipper.bool
      @result = subject.enable(@feature, @gate, @thing)
    end

    it 'logs operation' do
      expect(subject.count(:enable)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.enable(@feature, @gate, @thing))
    end
  end

  describe '#disable' do
    before do
      @feature = flipper[:stats]
      @gate = @feature.gate(:boolean)
      @thing = flipper.bool
      @result = subject.disable(@feature, @gate, @thing)
    end

    it 'logs operation' do
      expect(subject.count(:disable)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.disable(@feature, @gate, @thing))
    end
  end

  describe '#features' do
    before do
      flipper[:stats].enable
      @result = subject.features
    end

    it 'logs operation' do
      expect(subject.count(:features)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.features)
    end
  end

  describe '#add' do
    before do
      @feature = flipper[:stats]
      @result = subject.add(@feature)
    end

    it 'logs operation' do
      expect(subject.count(:add)).to be(1)
    end

    it 'returns result' do
      expect(@result).to eq(adapter.add(@feature))
    end
  end
end
