module RSpec
  module Mocks
    RSpec.describe "a double _not_ acting as a null object" do
      before(:each) do
        @double = double('non-null object')
      end

      it "says it does not respond to messages it doesn't understand" do
        expect(@double).not_to respond_to(:foo)
      end

      it "says it responds to messages it does understand" do
        allow(@double).to receive(:foo)
        expect(@double).to respond_to(:foo)
      end

      it "raises an error when interpolated in a string as an integer" do
        # Not sure why, but 1.9.2 (but not JRuby --1.9) raises a different
        # error than 1.8.7 and 1.9.3...
        expected_error = (RUBY_VERSION == '1.9.2' && RUBY_PLATFORM !~ /java/) ?
                         RSpec::Mocks::MockExpectationError :
                         TypeError

        expect { "%i" % @double }.to raise_error(expected_error)
      end
    end

    RSpec.describe "a double acting as a null object" do
      before(:each) do
        @double = double('null object').as_null_object
      end

      it "says it responds to everything" do
        expect(@double).to respond_to(:any_message_it_gets)
      end

      it "allows explicit stubs" do
        allow(@double).to receive(:foo) { "bar" }
        expect(@double.foo).to eq("bar")
      end

      it "allows explicit expectation" do
        expect(@double).to receive(:something)
        @double.something
      end

      it 'returns a string from `to_str`' do
        expect(@double.to_str).to be_a(String)
      end

      it 'continues to return self from an explicit expectation' do
        expect(@double).to receive(:bar)
        expect(@double.foo.bar).to be(@double)
      end

      it 'returns an explicitly stubbed value from an expectation with no implementation' do
        allow(@double).to receive_messages(:foo => "bar")
        expect(@double).to receive(:foo)
        expect(@double.foo).to eq("bar")
      end

      it "fails verification when explicit exception not met" do
        expect {
          expect(@double).to receive(:something)
          verify @double
        }.to fail
      end

      it "ignores unexpected methods" do
        @double.random_call("a", "d", "c")
        verify @double
      end

      it 'allows unexpected message sends using `send`' do
        val = @double.send(:foo).send(:bar)
        expect(val).to equal(@double)
      end

      it 'allows unexpected message sends using `__send__`' do
        val = @double.__send__(:foo).__send__(:bar)
        expect(val).to equal(@double)
      end

      it "allows expected message with different args first" do
        expect(@double).to receive(:message).with(:expected_arg)
        @double.message(:unexpected_arg)
        @double.message(:expected_arg)
      end

      it "allows expected message with different args second" do
        expect(@double).to receive(:message).with(:expected_arg)
        @double.message(:expected_arg)
        @double.message(:unexpected_arg)
      end

      it "can be interpolated in a string as an integer" do
        # This form of string interpolation calls
        # @double.to_int.to_int.to_int...etc until it gets an integer,
        # and thus gets stuck in an infinite loop unless our double
        # returns an int value from #to_int.
        expect(("%i" % @double)).to eq("0")
      end

      it "does not allow null objects to be used outside of examples" do
        RSpec::Mocks.teardown

        expect { @double.some.long.message.chain }.to raise_error(RSpec::Mocks::OutsideOfExampleError)
        expect { @double.as_null_object }.to raise_error(RSpec::Mocks::OutsideOfExampleError)
      end
    end

    RSpec.describe "#as_null_object" do
      it "sets the object to null_object" do
        obj = double('anything').as_null_object
        expect(obj).to be_null_object
      end
    end

    RSpec.describe "#null_object?" do
      it "defaults to false" do
        obj = double('anything')
        expect(obj).not_to be_null_object
      end
    end

    RSpec.describe "when using the :expect syntax" do
      include_context "with syntax", :expect

      it 'still supports null object doubles' do
        obj = double("foo").as_null_object
        expect(obj.foo.bar.bazz).to be(obj)
      end
    end
  end
end
