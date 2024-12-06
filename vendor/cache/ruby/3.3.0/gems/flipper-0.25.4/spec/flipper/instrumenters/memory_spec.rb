require 'flipper/instrumenters/memory'

RSpec.describe Flipper::Instrumenters::Memory do
  describe '#initialize' do
    it 'sets events to empty array' do
      instrumenter = described_class.new
      expect(instrumenter.events).to eq([])
    end
  end

  describe '#instrument' do
    it 'adds to events' do
      instrumenter = described_class.new
      name         = 'user.signup'
      payload      = { email: 'john@doe.com' }
      block_result = :yielded

      result = instrumenter.instrument(name, payload) { block_result }
      expect(result).to eq(block_result)

      event = described_class::Event.new(name, payload, block_result)
      expect(instrumenter.events).to eq([event])
    end

    context 'when an error is raised' do
      subject do
        instrumenter.instrument(:name) { raise IOError }
      end

      let(:instrumenter) { described_class.new }

      it 'captures and propagates the error' do
        expect { subject }.to raise_error(IOError)

        expect(instrumenter.events.count).to be 1

        payload = instrumenter.events[0].payload
        expect(payload.keys).to include(:exception, :exception_object)
        expect(payload[:exception_object]).to be_a IOError
      end
    end
  end
end
