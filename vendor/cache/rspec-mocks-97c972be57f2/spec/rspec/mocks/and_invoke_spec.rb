module RSpec
  module Mocks
    RSpec.describe 'and_invoke' do
      let(:obj) { double('obj') }

      context 'when a block is passed' do
        it 'raises ArgumentError' do
          expect {
            allow(obj).to receive(:foo).and_invoke('bar') { 'baz' }
          }.to raise_error(ArgumentError, /implementation block/i)
        end
      end

      context 'when no argument is passed' do
        it 'raises ArgumentError' do
          expect { allow(obj).to receive(:foo).and_invoke }.to raise_error(ArgumentError)
        end
      end

      context 'when a non-callable are passed in any position' do
        let(:non_callable) { nil }
        let(:callable) { lambda { nil } }

        it 'raises ArgumentError' do
          error = [ArgumentError, "Arguments to `and_invoke` must be callable."]

          expect { allow(obj).to receive(:foo).and_invoke(non_callable) }.to raise_error(*error)
          expect { allow(obj).to receive(:foo).and_invoke(callable, non_callable) }.to raise_error(*error)
        end
      end

      context 'when calling passed callables' do
        let(:dbl) { double }

        it 'passes the arguments into the callable' do
          expect(dbl).to receive(:square_then_cube).and_invoke(lambda { |i| i ** 2 },
                                                               lambda { |i| i ** 3 })

          expect(dbl.square_then_cube(2)).to eq 4
          expect(dbl.square_then_cube(2)).to eq 8
        end
      end
    end
  end
end
