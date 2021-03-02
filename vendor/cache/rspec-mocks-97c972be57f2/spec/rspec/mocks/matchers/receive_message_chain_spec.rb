module RSpec::Mocks::Matchers
  RSpec.describe "receive_message_chain" do
    let(:object) { double(:object) }

    context "with only the expect syntax enabled" do
      include_context "with syntax", :expect

      it "errors with a negative allowance" do
        expect {
          allow(object).not_to receive_message_chain(:to_a)
        }.to raise_error(RSpec::Mocks::NegationUnsupportedError)
      end

      it "errors with a negative expectation" do
        expect {
          expect(object).not_to receive_message_chain(:to_a)
        }.to raise_error(RSpec::Mocks::NegationUnsupportedError)
      end

      it "errors with a negative any_instance expectation" do
        expect {
          expect_any_instance_of(Object).not_to receive_message_chain(:to_a)
        }.to raise_error(RSpec::Mocks::NegationUnsupportedError)
      end

      it "errors with a negative any_instance allowance" do
        expect {
          allow_any_instance_of(Object).not_to receive_message_chain(:to_a)
        }.to raise_error(RSpec::Mocks::NegationUnsupportedError)
      end

      it "works with a do block" do
        allow(object).to receive_message_chain(:to_a, :length) do
          3
        end

        expect(object.to_a.length).to eq(3)
      end

      it "works with a {} block" do
        allow(object).to receive_message_chain(:to_a, :length) { 3 }

        expect(object.to_a.length).to eq(3)
      end

      it "gives the { } block prescedence over the do block" do
        allow(object).to receive_message_chain(:to_a, :length) { 3 } do
          4
        end

        expect(object.to_a.length).to eq(3)
      end

      it "works with and_return" do
        allow(object).to receive_message_chain(:to_a, :length).and_return(3)

        expect(object.to_a.length).to eq(3)
      end

      it "works with and_invoke" do
        allow(object).to receive_message_chain(:to_a, :length).and_invoke(lambda { raise "error" })

        expect { object.to_a.length }.to raise_error("error")
      end

      it "can constrain the return value by the argument to the last call" do
        allow(object).to receive_message_chain(:one, :plus).with(1) { 2 }
        allow(object).to receive_message_chain(:one, :plus).with(2) { 3 }
        expect(object.one.plus(1)).to eq(2)
        expect(object.one.plus(2)).to eq(3)
      end

      it "works with and_call_original", :pending => "See https://github.com/rspec/rspec-mocks/pull/467#issuecomment-28631621" do
        list = [1, 2, 3]
        expect(list).to receive_message_chain(:to_a, :length).and_call_original
        expect(list.to_a.length).to eq(3)
      end

      it "fails with and_call_original when the entire chain is not called", :pending => "See https://github.com/rspec/rspec-mocks/pull/467#issuecomment-28631621" do
        list = [1, 2, 3]
        expect(list).to receive_message_chain(:to_a, :length).and_call_original
        expect(list.to_a).to eq([1, 2, 3])
      end

      it "works with and_raise" do
        allow(object).to receive_message_chain(:to_a, :length).and_raise(StandardError.new("hi"))

        expect { object.to_a.length }.to raise_error(StandardError, "hi")
      end

      it "works with and_throw" do
        allow(object).to receive_message_chain(:to_a, :length).and_throw(:nope)

        expect { object.to_a.length }.to throw_symbol(:nope)
      end

      it "works with and_yield" do
        allow(object).to receive_message_chain(:to_a, :length).and_yield(3)

        expect { |blk| object.to_a.length(&blk) }.to yield_with_args(3)
      end

      it "works with a string of messages to chain" do
        allow(object).to receive_message_chain("to_a.length").and_yield(3)

        expect { |blk| object.to_a.length(&blk) }.to yield_with_args(3)
      end

      it "works with a hash return as the last argument in the chain" do
        allow(object).to receive_message_chain(:to_a, :length => 3)

        expect(object.to_a.length).to eq(3)
      end

      it "accepts any number of arguments to the stubbed messages" do
        allow(object).to receive_message_chain(:msg1, :msg2).and_return(:return_value)

        expect(object.msg1("nonsense", :value).msg2("another", :nonsense, 3.0, "value")).to eq(:return_value)
      end

      it "accepts any number of arguments to the stubbed messages with an inline hash return value" do
        allow(object).to receive_message_chain(:msg1, :msg2 => :return_value)

        expect(object.msg1("nonsense", :value).msg2("another", :nonsense, 3.0, "value")).to eq(:return_value)
      end

      it "raises when expect is used and some of the messages in the chain aren't called" do
        expect {
          expect(object).to receive_message_chain(:to_a, :farce, :length => 3)
          object.to_a
          verify_all
        }.to fail
      end

      it "raises when expect is used and all but the last message in the chain are called" do
        expect {
          expect(object).to receive_message_chain(:foo, :bar, :baz)
          object.foo.bar
          verify_all
        }.to fail
      end

      it "does not raise when expect is used and the entire chain is called" do
        expect {
          expect(object).to receive_message_chain(:to_a, :length => 3)
          object.to_a.length
          verify_all
        }.not_to raise_error
      end

      it "works with allow_any_instance" do
        o = Object.new

        allow_any_instance_of(Object).to receive_message_chain(:to_a, :length => 3)

        expect(o.to_a.length).to eq(3)
      end

      it "stubs already stubbed instances when using `allow_any_instance_of`" do
        o = Object.new
        allow(o).to receive(:foo).and_return(dbl = double)
        expect(o.foo).to be(dbl)

        allow_any_instance_of(Object).to receive_message_chain(:foo, :bar).and_return("bazz")
        expect(o.foo.bar).to eq("bazz")
      end

      it "fails when with expect_any_instance_of is used and the entire chain is not called" do
        expect {
          expect_any_instance_of(Object).to receive_message_chain(:to_a, :length => 3)
          verify_all
        }.to fail
      end

      it "affects previously stubbed instances when `expect_any_instance_of` is called" do
        o = Object.new
        allow(o).to receive(:foo).and_return(double)

        expect_any_instance_of(Object).to receive_message_chain(:foo, :bar => 3)
        expect(o.foo.bar).to eq(3)
      end

      it "passes when with expect_any_instance_of is used and the entire chain is called" do
        o = Object.new

        expect_any_instance_of(Object).to receive_message_chain(:to_a, :length => 3)
        o.to_a.length
      end

      it "works with expect where the first level of the chain is already expected" do
        o = Object.new
        expect(o).to receive(:foo).and_return(double)
        expect(o).to receive_message_chain(:foo, :bar, :baz)

        o.foo.bar.baz
      end

      it "works with allow where the first level of the chain is already expected" do
        o = Object.new
        expect(o).to receive(:foo).and_return(double)
        allow(o).to receive_message_chain(:foo, :bar, :baz).and_return(3)

        expect(o.foo.bar.baz).to eq(3)
      end

      it "works with expect where the first level of the chain is already stubbed" do
        o = Object.new
        allow(o).to receive(:foo).and_return(double)
        expect(o).to receive_message_chain(:foo, :bar, :baz)

        o.foo.bar.baz
      end

      it "works with allow where the first level of the chain is already stubbed" do
        o = Object.new
        allow(o).to receive(:foo).and_return(double)
        allow(o).to receive_message_chain(:foo, :bar, :baz).and_return(3)

        expect(o.foo.bar.baz).to eq(3)
      end

      it "provides a matcher description (when passing a string)" do
        matcher = receive_message_chain("foo.bar.bazz")
        expect(matcher.description).to eq("receive message chain foo.bar.bazz")
      end

      it "provides a matcher description (when passing symbols)" do
        matcher = receive_message_chain(:foo, :bar, :bazz)
        expect(matcher.description).to eq("receive message chain foo.bar.bazz")
      end

      it "provides a matcher description (when passing symbols and a hash)" do
        matcher = receive_message_chain(:foo, :bar, :bazz => 3)
        expect(matcher.description).to eq("receive message chain foo.bar.bazz")
      end
    end

    context "when the expect and should syntaxes are enabled" do
      include_context "with syntax", [:expect, :should]

      it "stubs the message correctly" do
        allow(object).to receive_message_chain(:to_a, :length)

        expect { object.to_a.length }.not_to raise_error
      end
    end
  end
end
