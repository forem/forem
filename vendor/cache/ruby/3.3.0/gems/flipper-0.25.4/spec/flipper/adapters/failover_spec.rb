require 'dalli'
require 'flipper/adapters/failover'
require 'net/http'
require 'pstore'
require 'redis'

RSpec.describe Flipper::Adapters::Failover do
  subject { described_class.new(primary, secondary, options) }

  let(:primary) { Flipper::Adapters::Memory.new }
  let(:secondary) { Flipper::Adapters::Memory.new }
  let(:options) { {} }
  let(:flipper) { Flipper.new(subject) }

  context 'when the primary is a functioning adapter' do
    it_should_behave_like 'a flipper adapter'

    it 'should not call the secondary' do
      expect(secondary).not_to receive(:features)
      subject.features
    end

    it 'should not write to secondary' do
      expect(secondary).not_to receive(:add)
      expect(secondary).not_to receive(:enable)

      flipper[:flag].enable
    end

    context 'when dual_write is enabled' do
      let(:options) { { dual_write: true } }

      it_should_behave_like 'a flipper adapter'

      it 'writes to both primary and secondary' do
        expect(primary).to receive(:add).and_call_original
        expect(primary).to receive(:enable).and_call_original

        expect(secondary).to receive(:add)
        expect(secondary).to receive(:enable)

        flipper[:flag].enable
      end
    end
  end

  context 'when primary fails during read operations' do
    before do
      allow(primary).to receive(:features).and_raise(Redis::ConnectionError)
      allow(primary).to receive(:get).and_raise(Dalli::NetworkError)
    end

    it 'fails over to the secondary adapter for reads' do
      expect(secondary).to receive(:features)
      subject.features

      flipper[:flag].enable
      expect(secondary).to receive(:get).and_call_original
      flipper[:flag].enabled?
    end

    context 'when dual_write is enabled' do
      let(:options) { { dual_write: true } }

      it_should_behave_like 'a flipper adapter'
    end
  end

  context 'when primary fails during write operations' do
    before do
      allow(primary).to receive(:add).and_raise(PStore::Error)
    end

    let(:options) { { dual_write: true } }

    it 'fails and does not write to secondary adapter' do
      expect(secondary).not_to receive(:add)
      expect(secondary).not_to receive(:enable)

      expect { flipper[:flag].enable }.to raise_error(PStore::Error)
    end
  end

  context 'when primary is instrumented and fails' do
    before do
      allow(memory_adapter).to receive(:get).and_raise(Net::ReadTimeout)
    end

    let(:memory_adapter) { Flipper::Adapters::Memory.new }
    let(:primary) do
      Flipper::Adapters::Instrumented.new(
        memory_adapter,
        instrumenter: instrumenter,
      )
    end
    let(:instrumenter) { Flipper::Instrumenters::Memory.new }

    it 'logs the raised exception' do
      flipper[:flag].enabled?

      expect(instrumenter.events.count).to be 1

      payload = instrumenter.events[0].payload
      expect(payload.keys).to include(:exception, :exception_object)
      expect(payload[:exception_object]).to be_a Net::ReadTimeout
    end
  end

  context 'when adapter raises a SyntaxError' do
    before do
      allow(primary).to receive(:features).and_raise(SyntaxError)
    end

    it 'does not rescue this type by default' do
      expect {
        subject.features
      }.to raise_error(SyntaxError)
    end

    context 'when Failover adapter is configured to catch SyntaxError' do
      let(:options) { { errors: [ SyntaxError ] } }

      it 'fails over to secondary adapter' do
        expect(secondary).to receive(:features)
        subject.features
      end
    end
  end
end
