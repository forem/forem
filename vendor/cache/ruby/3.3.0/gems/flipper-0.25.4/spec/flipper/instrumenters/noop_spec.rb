RSpec.describe Flipper::Instrumenters::Noop do
  describe '.instrument' do
    context 'with name' do
      it 'yields block' do
        expect { |block|
          described_class.instrument(:foo, &block)
        }.to yield_control
      end
    end

    context 'with name and payload' do
      let(:payload) { { pay: :load } }

      it 'yields block' do
        expect { |block|
          described_class.instrument(:foo, payload, &block)
        }.to yield_control
      end

      it 'yields the payload' do
        described_class.instrument(:foo, payload) do |block_payload|
          expect(block_payload).to eq payload
        end
      end
    end
  end
end
