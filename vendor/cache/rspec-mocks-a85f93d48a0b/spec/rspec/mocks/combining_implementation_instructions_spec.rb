module RSpec
  module Mocks
    RSpec.describe "Combining implementation instructions" do
      it 'can combine and_yield and and_return' do
        dbl = double
        allow(dbl).to receive(:foo).and_yield(5).and_return(3)

        expect { |b|
          expect(dbl.foo(&b)).to eq(3)
        }.to yield_with_args(5)
      end

      describe "combining and_yield, a block implementation and and_return" do
        def verify_combined_implementation
          dbl = double
          (yield dbl).and_yield(5).and_return(3)

          expect { |b|
            expect(dbl.foo(:arg, &b)).to eq(3)
          }.to yield_with_args(5)

          expect(@block_called).to be_truthy
        end

        it 'works when passing a block to `stub`' do
          verify_combined_implementation do |dbl|
            allow(dbl).to receive(:foo) { @block_called = true }
          end
        end

        it 'works when passing a block to `with`' do
          verify_combined_implementation do |dbl|
            allow(dbl).to receive(:foo).with(:arg) { @block_called = true }
          end
        end

        it 'works when passing a block to `exactly`' do
          verify_combined_implementation do |dbl|
            expect(dbl).to receive(:foo).exactly(:once) { @block_called = true }
          end
        end

        it 'works when passing a block to `at_least`' do
          verify_combined_implementation do |dbl|
            expect(dbl).to receive(:foo).at_least(:once) { @block_called = true }
          end
        end

        it 'works when passing a block to `at_most`' do
          verify_combined_implementation do |dbl|
            expect(dbl).to receive(:foo).at_most(:once) { @block_called = true }
          end
        end

        it 'works when passing a block to `times`' do
          verify_combined_implementation do |dbl|
            expect(dbl).to receive(:foo).exactly(1).time { @block_called = true }
          end
        end

        it 'works when passing a block to `once`' do
          verify_combined_implementation do |dbl|
            expect(dbl).to receive(:foo).once { @block_called = true }
          end
        end

        it 'works when passing a block to `twice`' do
          the_double = nil

          verify_combined_implementation do |dbl|
            the_double = dbl
            expect(dbl).to receive(:foo).twice { @block_called = true }
          end

          the_double.foo { |_| } # to ensure it is called twice
        end

        it 'works when passing a block to `ordered`' do
          verify_combined_implementation do |dbl|
            expect(dbl).to receive(:foo).ordered { @block_called = true }
          end
        end
      end

      it 'can combine and_yield and and_raise' do
        dbl = double
        allow(dbl).to receive(:foo).and_yield(5).and_raise("boom")

        expect { |b|
          expect { dbl.foo(&b) }.to raise_error("boom")
        }.to yield_with_args(5)
      end

      it 'can combine and_yield, a block implementation and and_raise' do
        dbl = double
        block_called = false
        allow(dbl).to receive(:foo) { block_called = true }.and_yield(5).and_raise("boom")

        expect { |b|
          expect { dbl.foo(&b) }.to raise_error("boom")
        }.to yield_with_args(5)

        expect(block_called).to be_truthy
      end

      it 'can combine and_yield and and_throw' do
        dbl = double
        allow(dbl).to receive(:foo).and_yield(5).and_throw(:bar)

        expect { |b|
          expect { dbl.foo(&b) }.to throw_symbol(:bar)
        }.to yield_with_args(5)
      end

      it 'can combine and_yield, a block implementation and and_throw' do
        dbl = double
        block_called = false
        allow(dbl).to receive(:foo) { block_called = true }.and_yield(5).and_throw(:bar)

        expect { |b|
          expect { dbl.foo(&b) }.to throw_symbol(:bar)
        }.to yield_with_args(5)

        expect(block_called).to be_truthy
      end

      describe "a double that already has a terminal `and_return(x)` action" do
        let(:the_dbl) { double }
        let(:stubbed_double) { allow(the_dbl).to receive(:foo) }
        before { stubbed_double.and_return(1) }

        it 'allows the terminal action to be overridden to `and_return(y)`' do
          stubbed_double.and_return(3)
          expect(the_dbl.foo).to eq(3)
        end

        it 'allows the terminal action to be overridden to `and_raise(y)`' do
          stubbed_double.and_raise("boom")
          expect { the_dbl.foo }.to raise_error("boom")
        end

        it 'allows the terminal action to be overridden to `and_throw(y)`' do
          stubbed_double.and_throw(:bar)
          expect { the_dbl.foo }.to throw_symbol(:bar)
        end
      end

      describe "a double that already has a terminal block action" do
        let(:the_dbl) { double }
        let(:stubbed_double) { allow(the_dbl).to receive(:foo) }

        it "allows the block action to be overridden" do
          allow(RSpec).to receive(:warning)
          stubbed_double.with(:arg) { :with_block }
          stubbed_double.at_least(:once) { :at_least_block }
          expect(the_dbl.foo(:arg)).to eq(:at_least_block)
        end
      end

      it 'warns when the inner implementation block is overridden' do
        expect(RSpec).to receive(:warning).with(/overriding a previous stub implementation of `foo`.*#{__FILE__}:#{__LINE__ + 1}/)
        allow(double).to receive(:foo).with(:arg) { :with_block }.at_least(:once) { :at_least_block }
      end

      it "does not warn about overriding the stub when `:with` is chained off the block" do
        expect(RSpec).not_to receive(:warning)

        obj = Object.new
        stub = allow(obj).to receive(:foo) {}
        stub.with(1)
      end

      it 'can combine and_call_original, with, and_return' do
        obj = Struct.new(:value).new('original')
        allow(obj).to receive(:value).and_call_original
        allow(obj).to receive(:value).with(:arg).and_return('value')
        expect(obj.value).to eq 'original'
        expect(obj.value(:arg)).to eq 'value'
      end

      it 'raises an error if `and_call_original` is followed by any other instructions' do
        allow(RSpec).to receive(:warning)
        dbl = [1, 2, 3]
        stubbed = allow(dbl).to receive(:size)
        stubbed.and_call_original

        msg_fragment = /cannot be modified further/

        expect { stubbed.and_yield }.to raise_error(msg_fragment)
        expect { stubbed.and_return(1) }.to raise_error(msg_fragment)
        expect { stubbed.and_raise("a") }.to raise_error(msg_fragment)
        expect { stubbed.and_throw(:bar) }.to raise_error(msg_fragment)

        expect { stubbed.once {} }.to raise_error(msg_fragment)

        expect(dbl.size).to eq(3)
      end
    end
  end
end
