module RSpec
  module Mocks
    RSpec.describe "After a test double has been torn down" do
      RSpec.shared_examples_for "expiration" do
        before do
          expect(dbl).to receive(:foo).at_least(:once)
          allow(dbl).to receive(:bar)
          dbl.foo

          RSpec::Mocks.verify
          RSpec::Mocks.teardown
          RSpec::Mocks.setup
        end

        it 'disallows previously mocked methods' do
          expect { dbl.foo }.to raise_error(ExpiredTestDoubleError)
        end

        it 'disallows previously stubbed methods' do
          expect { dbl.bar }.to raise_error(ExpiredTestDoubleError)
        end

        it 'disallows stubbing new methods (with receive)' do
          expect {
            allow(dbl).to receive(:bazz)
          }.to raise_error(ExpiredTestDoubleError)
        end

        it 'disallows stubbing new methods (with receive_messages)' do
          expect {
            allow(dbl).to receive_messages(:bazz => 3)
          }.to raise_error(ExpiredTestDoubleError)
        end

        it 'disallows stubbing new message chains' do
          expect {
            allow(dbl).to receive_message_chain(:bazz, :bam, :goo)
          }.to raise_error(ExpiredTestDoubleError)
        end

        it 'disallows mocking new methods' do
          expect {
            expect(dbl).to receive(:bazz)
          }.to raise_error(ExpiredTestDoubleError)
        end

        it 'disallows being turned into a null object' do
          expect { dbl.as_null_object }.to raise_error(ExpiredTestDoubleError)
        end

        it 'disallows being checked for nullness' do
          expect { dbl.null_object? }.to raise_error(ExpiredTestDoubleError)
        end

      end

      context "for a plain double" do
        let(:dbl) { double }
        include_examples "expiration"
      end

      class ExpiredInstanceInterface
        def foo;  end
        def bar;  end
        def bazz; end
      end

      class ExpiredClassInterface
        def self.foo;  end
        def self.bar;  end
        def self.bazz; end
      end

      context "for an instance_double" do
        let(:dbl) { instance_double(ExpiredInstanceInterface) }
        include_examples "expiration"
      end

      context "for a class_double" do
        let(:dbl) { class_double(ExpiredClassInterface) }
        include_examples "expiration"
      end

      context "for an object_double" do
        let(:dbl) { object_double(ExpiredInstanceInterface.new) }
        include_examples "expiration"
      end
    end
  end
end
