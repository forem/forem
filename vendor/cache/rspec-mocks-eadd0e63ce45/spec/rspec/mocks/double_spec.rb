module RSpec
  module Mocks
    RSpec.describe Double do
      before(:each) { @double = double("test double") }
      after(:each)  { reset @double }

      it "has method_missing as private" do
        expect(RSpec::Mocks::Double.private_instance_methods).to include_method(:method_missing)
      end

      it "does not respond_to? method_missing (because it's private)" do
        expect(RSpec::Mocks::Double.new).not_to respond_to(:method_missing)
      end

      it "uses 'Double' in failure messages" do
        dbl = double('name')
        expect { dbl.foo }.to raise_error(/#<Double "name"> received/)
      end

      it "hides internals in its inspect representation" do
        m = double('cup')
        expect(m.inspect).to eq('#<Double "cup">')
      end

      it 'does not blow up when resetting standard object methods' do
        dbl = double(:tainted? => true)
        expect(dbl.tainted?).to eq(true)
        expect { reset dbl }.not_to raise_error
      end

      it 'does not get string vs symbol messages confused' do
        dbl = double("foo" => 1)
        allow(dbl).to receive(:foo).and_return(2)
        expect(dbl.foo).to eq(2)
        expect { reset dbl }.not_to raise_error
      end

      it "generates the correct error when an unfulfilled expectation uses an unused double as a `with` argument" do
        expect {
          a = double('a')
          b = double('b')
          expect(a).to receive(:append).with(b)
          verify_all
        }.to fail
      end

      it 'allows string representation of methods in constructor' do
        dbl = double('foo' => 1)
        expect(dbl.foo).to eq(1)
      end

      it 'allows setter methods to be stubbed' do
        dbl = double('foo=' => 1)

        # Note the specified return value is thrown away. This is a Ruby semantics
        # thing. You cannot change the return value of assignment.
        expect(dbl.foo = "bar").to eq("bar")
      end

      it 'allows `class` to be stubbed even when `any_instance` has already been used' do
        # See https://github.com/rspec/rspec-mocks/issues/687
        # The infinite recursion code path was only triggered when there were
        # active any instance recorders in the current example, so we make one here.
        allow_any_instance_of(Object).to receive(:bar).and_return(2)

        dbl = double(:foo => 1, :class => String)
        expect(dbl.foo).to eq(1)
        expect(dbl.class).to eq(String)
      end

      it 'allows `send` to be stubbed' do
        dbl = double
        allow(dbl).to receive(:send).and_return("received")
        expect(dbl.send(:some_msg)).to eq("received")
      end

      it "reports line number of expectation of unreceived message" do
        expected_error_line = __LINE__; expect(@double).to receive(:wont_happen).with("x", 3)
        expect {
          verify @double
        }.to fail { |e|
          # NOTE - this regexp ended w/ $, but jruby adds extra info at the end of the line
          expect(e.backtrace[0]).to match(/#{File.basename(__FILE__)}:#{expected_error_line}/)
        }
      end

      it "reports line number of expectation of unreceived message after a message expectation after similar stub" do
        allow(@double).to receive(:wont_happen)
        expected_error_line = __LINE__; expect(@double).to receive(:wont_happen).with("x", 3)
        expect {
          verify @double
        }.to fail { |e|
          # NOTE - this regexp ended w/ $, but jruby adds extra info at the end of the line
          expect(e.backtrace[0]).to match(/#{File.basename(__FILE__)}:#{expected_error_line}/)
        }
      end

      it "passes when not receiving message specified as not to be received" do
        expect(@double).not_to receive(:not_expected)
        verify @double
      end

      it "prevents confusing double-negative expressions involving `never`" do
        expect {
          expect(@double).not_to receive(:not_expected).never
        }.to raise_error(/trying to negate it again/)
      end

      it "warns when `and_return` is called on a negative expectation" do
        expect {
          expect(@double).not_to receive(:do_something).and_return(1)
        }.to raise_error(/not supported/)

        expect {
          expect(@double).not_to receive(:do_something).and_return(1)
        }.to raise_error(/not supported/)

        expect {
          expect(@double).to receive(:do_something).never.and_return(1)
        }.to raise_error(/not supported/)
      end

      it "passes when receiving message specified as not to be received with different args" do
        expect(@double).not_to receive(:message).with("unwanted text")
        expect(@double).to receive(:message).with("other text")
        @double.message "other text"
        verify @double
      end

      it "fails when receiving message specified as not to be received" do
        expect(@double).not_to receive(:not_expected)
        expect {
          @double.not_expected
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          %Q|(Double "test double").not_expected(no args)\n    expected: 0 times with any arguments\n    received: 1 time|
        )
      end

      it "fails when receiving message specified as not to be received with args" do
        expect(@double).not_to receive(:not_expected).with("unexpected text")
        expect {
          @double.not_expected("unexpected text")
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          %Q|(Double "test double").not_expected("unexpected text")\n    expected: 0 times with arguments: ("unexpected text")\n    received: 1 time with arguments: ("unexpected text")|
        )
      end

      it "fails when array arguments do not match" do
        expect(@double).not_to receive(:not_expected).with(["do not want"])
        expect {
          @double.not_expected(["do not want"])
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          %Q|(Double "test double").not_expected(["do not want"])\n    expected: 0 times with arguments: (["do not want"])\n    received: 1 time with arguments: (["do not want"])|
        )
      end

      context "when specifying a message should not be received with specific args" do
        context "using `expect(...).not_to receive()`" do
          it 'passes when receiving the message with different args' do
            expect(@double).not_to receive(:not_expected).with("unexpected text")
            @double.not_expected "really unexpected text"
            verify @double
          end
        end

        context "using `expect(...).to receive().never`" do
          it 'passes when receiving the message with different args' do
            expect(@double).to receive(:not_expected).with("unexpected text").never
            @double.not_expected "really unexpected text"
            verify @double
          end
        end
      end

      it 'does not get confused when a negative expectation is used with a string and symbol message' do
        allow(@double).to receive(:foo) { 3 }
        expect(@double).not_to receive(:foo).with(1)
        expect(@double).not_to receive("foo").with(2)

        expect(@double.foo).to eq(3)
        verify @double
      end

      it 'does not get confused when a positive expectation is used with a string and symbol message' do
        expect(@double).to receive(:foo).with(1)
        expect(@double).to receive("foo").with(2)

        @double.foo(1)
        @double.foo(2)

        verify @double
      end

      it "allows parameter as return value" do
        expect(@double).to receive(:something).with("a", "b", "c").and_return("booh")
        expect(@double.something("a", "b", "c")).to eq "booh"
        verify @double
      end

      it "returns the previously stubbed value if no return value is set" do
        allow(@double).to receive(:something).with("a", "b", "c").and_return(:stubbed_value)
        expect(@double).to receive(:something).with("a", "b", "c")
        expect(@double.something("a", "b", "c")).to eq :stubbed_value
        verify @double
      end

      it "returns nil if no return value is set and there is no previously stubbed value" do
        expect(@double).to receive(:something).with("a", "b", "c")
        expect(@double.something("a", "b", "c")).to be_nil
        verify @double
      end

      it "raises exception if args don't match when method called" do
        expect(@double).to receive(:something).with("a", "b", "c").and_return("booh")
        expect {
          @double.something("a", "d", "c")
        }.to fail_with "#<Double \"test double\"> received :something with unexpected arguments\n  expected: (\"a\", \"b\", \"c\")\n       got: (\"a\", \"d\", \"c\")"
      end

      describe "even when a similar expectation with different arguments exist" do
        it "raises exception if args don't match when method called, correctly reporting the offending arguments" do
          expect(@double).to receive(:something).with("a", "b", "c").once
          expect(@double).to receive(:something).with("z", "x", "c").once
          expect {
            @double.something("a", "b", "c")
            @double.something("z", "x", "g")
          }.to fail_with "#<Double \"test double\"> received :something with unexpected arguments\n  expected: (\"z\", \"x\", \"c\")\n       got: (\"z\", \"x\", \"g\")"
        end
      end

      it "raises exception if args don't match when method called even when the method is stubbed" do
        allow(@double).to receive(:something)
        expect(@double).to receive(:something).with("a", "b", "c")
        expect {
          @double.something("a", "d", "c")
          verify @double
        }.to fail_with "#<Double \"test double\"> received :something with unexpected arguments\n  expected: (\"a\", \"b\", \"c\")\n       got: (\"a\", \"d\", \"c\")"
      end

      it "raises exception if args don't match when method called even when using null_object" do
        @double = double("test double").as_null_object
        expect(@double).to receive(:something).with("a", "b", "c")
        expect {
          @double.something("a", "d", "c")
          verify @double
        }.to fail_with "#<Double \"test double\"> received :something with unexpected arguments\n  expected: (\"a\", \"b\", \"c\")\n       got: (\"a\", \"d\", \"c\")"
      end

      describe 'with a method that has a default argument' do
        it "raises an exception if the arguments don't match when the method is called, correctly reporting the offending arguments" do
          def @double.method_with_default_argument(_={}); end
          expect(@double).to receive(:method_with_default_argument).with({})

          expect {
            @double.method_with_default_argument(nil)
            verify @double
          }.to fail_with a_string_starting_with("#<Double \"test double\"> received :method_with_default_argument with unexpected arguments\n  expected: ({})\n       got: (nil)")
        end
      end

      it "fails if unexpected method called" do
        expect {
          @double.something("a", "b", "c")
        }.to fail_with "#<Double \"test double\"> received unexpected message :something with (\"a\", \"b\", \"c\")"
      end

      it "uses block for expectation if provided" do
        expect(@double).to receive(:something) do | a, b |
          expect(a).to eq "a"
          expect(b).to eq "b"
          "booh"
        end
        expect(@double.something("a", "b")).to eq "booh"
        verify @double
      end

      it "fails if expectation block fails" do
        expect(@double).to receive(:something) do |bool|
          expect(bool).to be_truthy
        end

        expect {
          @double.something false
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it "is wrappable in an array" do
        with_isolated_stderr do
          expect(Array(@double)).to eq([@double])
        end
      end

      it "is wrappable in an array when a null object" do
        with_isolated_stderr do
          expect(Array(@double.as_null_object)).to eq [@double]
        end
      end

      it "responds to to_ary as a null object" do
        expect(@double.as_null_object.to_ary).to eq nil
      end

      it "responds to to_a as a null object" do
        if RUBY_VERSION.to_f > 1.8
          expect(@double.as_null_object.to_a).to eq nil
        else
          with_isolated_stderr do
            expect(@double.as_null_object.to_a).to eq [@double]
          end
        end
      end

      it "passes proc to expectation block without an argument" do
        expect(@double).to receive(:foo) { |&block| expect(block.call).to eq(:bar) }
        @double.foo { :bar }
      end

      it "passes proc to expectation block with an argument" do
        expect(@double).to receive(:foo) { |_, &block| expect(block.call).to eq(:bar) }
        @double.foo(:arg) { :bar }
      end

      it "passes proc to stub block without an argurment" do
        allow(@double).to receive(:foo) { |&block| expect(block.call).to eq(:bar) }
        @double.foo { :bar }
      end

      it "passes proc to stub block with an argument" do
        allow(@double).to receive(:foo) { |_, &block| expect(block.call).to eq(:bar) }
        @double.foo(:arg) { :bar }
      end

      it "fails right away when method defined as never is received" do
        expect(@double).to receive(:not_expected).never
        expect { @double.not_expected }.
          to fail_with %Q|(Double "test double").not_expected(no args)\n    expected: 0 times with any arguments\n    received: 1 time|
      end

      it "raises RuntimeError by default" do
        expect(@double).to receive(:something).and_raise
        expect { @double.something }.to raise_error(RuntimeError)
      end

      it "raises RuntimeError with a message by default" do
        expect(@double).to receive(:something).and_raise("error message")
        expect { @double.something }.to raise_error(RuntimeError, "error message")
      end

      it "raises an exception of a given type without an error message" do
        expect(@double).to receive(:something).and_raise(StandardError)
        expect { @double.something }.to raise_error(StandardError)
      end

      it "raises an exception of a given type with a message" do
        expect(@double).to receive(:something).and_raise(RuntimeError, "error message")
        expect { @double.something }.to raise_error(RuntimeError, "error message")
      end

      it "raises a given instance of an exception" do
        expect(@double).to receive(:something).and_raise(RuntimeError.new("error message"))
        expect { @double.something }.to raise_error(RuntimeError, "error message")
      end

      class OutOfGas < StandardError
        attr_reader :amount, :units
        def initialize(amount, units)
          @amount = amount
          @units  = units
        end
      end

      it "raises a given instance of an exception with arguments other than the standard 'message'" do
        expect(@double).to receive(:something).and_raise(OutOfGas.new(2, :oz))

        expect {
          @double.something
        }.to raise_error(OutOfGas) { |e|
          expect(e.amount).to eq 2
          expect(e.units).to eq :oz
        }
      end

      it "does not raise when told to if args dont match" do
        expect(@double).to receive(:something).with(2).and_raise(RuntimeError)
        expect {
          @double.something 1
        }.to fail
      end

      it "throws when told to" do
        expect(@double).to receive(:something).and_throw(:blech)
        expect {
          @double.something
        }.to throw_symbol(:blech)
      end

      it "ignores args on any args" do
        expect(@double).to receive(:something).at_least(:once).with(any_args)
        @double.something
        @double.something 1
        @double.something "a", 2
        @double.something [], {}, "joe", 7
        verify @double
      end

      it "fails on no args if any args received" do
        expect(@double).to receive(:something).with(no_args)
        expect {
          @double.something 1
        }.to fail_with "#<Double \"test double\"> received :something with unexpected arguments\n  expected: (no args)\n       got: (1)"
      end

      it "fails when args are expected but none are received" do
        expect(@double).to receive(:something).with(1)
        expect {
          @double.something
        }.to fail_with "#<Double \"test double\"> received :something with unexpected arguments\n  expected: (1)\n       got: (no args)"
      end

      it "returns value from block by default" do
        allow(@double).to receive(:method_that_yields).and_yield
        value = @double.method_that_yields { :returned_obj }
        expect(value).to eq :returned_obj
        verify @double
      end

      it "yields 0 args to blocks that take a variable number of arguments" do
        expect(@double).to receive(:yield_back).with(no_args).once.and_yield
        a = nil
        @double.yield_back { |*x| a = x }
        expect(a).to eq []
        verify @double
      end

      it "yields 0 args multiple times to blocks that take a variable number of arguments" do
        expect(@double).to receive(:yield_back).once.with(no_args).once.and_yield.
                                                                    and_yield
        b = []
        @double.yield_back { |*a| b << a }
        expect(b).to eq [[], []]
        verify @double
      end

      it "yields one arg to blocks that take a variable number of arguments" do
        expect(@double).to receive(:yield_back).with(no_args).once.and_yield(99)
        a = nil
        @double.yield_back { |*x| a = x }
        expect(a).to eq [99]
        verify @double
      end

      it "yields one arg 3 times consecutively to blocks that take a variable number of arguments" do
        expect(@double).to receive(:yield_back).once.with(no_args).once.and_yield(99).
                                                                    and_yield(43).
                                                                    and_yield("something fruity")
        b = []
        @double.yield_back { |*a| b << a }
        expect(b).to eq [[99], [43], ["something fruity"]]
        verify @double
      end

      it "yields many args to blocks that take a variable number of arguments" do
        expect(@double).to receive(:yield_back).with(no_args).once.and_yield(99, 27, "go")
        a = nil
        @double.yield_back { |*x| a = x }
        expect(a).to eq [99, 27, "go"]
        verify @double
      end

      it "yields many args 3 times consecutively to blocks that take a variable number of arguments" do
        expect(@double).to receive(:yield_back).once.with(no_args).once.and_yield(99, :green, "go").
                                                                    and_yield("wait", :amber).
                                                                    and_yield("stop", 12, :red)
        b = []
        @double.yield_back { |*a| b << a }
        expect(b).to eq [[99, :green, "go"], ["wait", :amber], ["stop", 12, :red]]
        verify @double
      end

      it "yields single value" do
        expect(@double).to receive(:yield_back).with(no_args).once.and_yield(99)
        a = nil
        @double.yield_back { |x| a = x }
        expect(a).to eq 99
        verify @double
      end

      it "yields single value 3 times consecutively" do
        expect(@double).to receive(:yield_back).once.with(no_args).once.and_yield(99).
                                                                    and_yield(43).
                                                                    and_yield("something fruity")
        b = []
        @double.yield_back { |a| b << a }
        expect(b).to eq [99, 43, "something fruity"]
        verify @double
      end

      it "yields two values" do
        expect(@double).to receive(:yield_back).with(no_args).once.and_yield('wha', 'zup')
        a, b = nil
        @double.yield_back { |x, y| a = x; b = y }
        expect(a).to eq 'wha'
        expect(b).to eq 'zup'
        verify @double
      end

      it "yields two values 3 times consecutively" do
        expect(@double).to receive(:yield_back).once.with(no_args).once.and_yield('wha', 'zup').
                                                                    and_yield('not', 'down').
                                                                    and_yield(14, 65)
        c = []
        @double.yield_back { |a, b| c << [a, b] }
        expect(c).to eq [%w[wha zup], %w[not down], [14, 65]]
        verify @double
      end

      it "fails when calling yielding method with wrong arity" do
        expect(@double).to receive(:yield_back).with(no_args).once.and_yield('wha', 'zup')
        expect {
          @double.yield_back { |_| }
        }.to fail_with "#<Double \"test double\"> yielded |\"wha\", \"zup\"| to block with arity of 1"
      end

      if kw_args_supported?
        it 'fails when calling yielding method with invalid kw args' do
          expect(@double).to receive(:yield_back).and_yield(:x => 1, :y => 2)
          expect {
            eval("@double.yield_back { |x: 1| }")
          }.to fail_with '#<Double "test double"> yielded |{:x=>1, :y=>2}| to block with optional keyword args (:x)'
        end
      end

      it "fails when calling yielding method consecutively with wrong arity" do
        expect(@double).to receive(:yield_back).once.with(no_args).and_yield('wha', 'zup').
                                                                     and_yield('down').
                                                                     and_yield(14, 65)
        expect {
          c = []
          @double.yield_back { |a, b| c << [a, b] }
        }.to fail_with "#<Double \"test double\"> yielded |\"down\"| to block with arity of 2"
      end

      it "fails when calling yielding method without block" do
        expect(@double).to receive(:yield_back).with(no_args).once.and_yield('wha', 'zup')
        expect {
          @double.yield_back
        }.to fail_with "#<Double \"test double\"> asked to yield |[\"wha\", \"zup\"]| but no block was passed"
      end

      it "is able to double send" do
        expect(@double).to receive(:send).with(any_args)
        @double.send 'hi'
        verify @double
      end

      it "is able to raise from method calling yielding double" do
        expect(@double).to receive(:yield_me).and_yield 44

        expect {
          @double.yield_me do |_|
            raise "Bang"
          end
        }.to raise_error(StandardError, "Bang")

        verify @double
      end

      it "clears expectations after verify" do
        expect(@double).to receive(:foobar)
        @double.foobar
        verify @double
        expect {
          @double.foobar
        }.to fail_with %q|#<Double "test double"> received unexpected message :foobar with (no args)|
      end

      it "restores objects to their original state on rspec_reset" do
        dbl = double("this is a double")
        expect(dbl).to receive(:blah)
        reset dbl
        verify dbl # should throw if reset didn't work
      end

      it "temporarily replaces a method stub on a double" do
        allow(@double).to receive(:msg).and_return(:stub_value)
        expect(@double).to receive(:msg).with(:arg).and_return(:double_value)
        expect(@double.msg(:arg)).to equal(:double_value)
        expect(@double.msg).to equal(:stub_value)
        expect(@double.msg).to equal(:stub_value)
        verify @double
      end

      it "does not require a different signature to replace a method stub" do
        allow(@double).to receive(:msg).and_return(:stub_value)
        expect(@double).to receive(:msg).and_return(:double_value)
        expect(@double.msg(:arg)).to equal(:double_value)
        expect(@double.msg).to equal(:stub_value)
        expect(@double.msg).to equal(:stub_value)
        verify @double
      end

      it "raises an error when a previously stubbed method has a negative expectation" do
        allow(@double).to receive(:msg).and_return(:stub_value)
        expect(@double).not_to receive(:msg)
        expect { @double.msg(:arg) }.to fail
      end

      it "temporarily replaces a method stub on a non-double" do
        non_double = Object.new
        allow(non_double).to receive(:msg).and_return(:stub_value)
        expect(non_double).to receive(:msg).with(:arg).and_return(:double_value)
        expect(non_double.msg(:arg)).to equal(:double_value)
        expect(non_double.msg).to equal(:stub_value)
        expect(non_double.msg).to equal(:stub_value)
        verify non_double
      end

      it "returns the stubbed value when no new value specified" do
        allow(@double).to receive(:msg).and_return(:stub_value)
        expect(@double).to receive(:msg)
        expect(@double.msg).to equal(:stub_value)
        verify @double
      end

      it "returns the stubbed value when stubbed with args and no new value specified" do
        allow(@double).to receive(:msg).with(:arg).and_return(:stub_value)
        expect(@double).to receive(:msg).with(:arg)
        expect(@double.msg(:arg)).to equal(:stub_value)
        verify @double
      end

      it "does not mess with the stub's yielded values when also doubleed" do
        allow(@double).to receive(:yield_back).and_yield(:stub_value)
        expect(@double).to receive(:yield_back).and_yield(:double_value)
        @double.yield_back { |v| expect(v).to eq :double_value }
        @double.yield_back { |v| expect(v).to eq :stub_value }
        verify @double
      end

      it "can yield multiple times when told to do so" do
        allow(@double).to receive(:foo).and_yield(:stub_value)
        expect(@double).to receive(:foo).and_yield(:first_yield).and_yield(:second_yield)

        expect { |b| @double.foo(&b) }.to yield_successive_args(:first_yield, :second_yield)
        expect { |b| @double.foo(&b) }.to yield_with_args(:stub_value)

        verify @double
      end

      it "assigns stub return values" do
        dbl = RSpec::Mocks::Double.new('name', :message => :response)
        expect(dbl.message).to eq :response
      end

      describe "a double message receiving a block" do
        before(:each) do
          @double = double("double")
          @calls = 0
        end

        def add_call
          @calls += 1
        end

        it "supports a block passed to `receive` for `expect`" do
          expect(@double).to receive(:foo) { add_call }

          @double.foo

          expect(@calls).to eq 1
        end

        it "supports a block passed to `receive` for `expect` after a similar stub" do
          allow(@double).to receive(:foo).and_return(:bar)
          expect(@double).to receive(:foo) { add_call }

          @double.foo

          expect(@calls).to eq 1
        end

        it "calls the block after #once" do
          expect(@double).to receive(:foo).once { add_call }

          @double.foo

          expect(@calls).to eq 1
        end

        it "calls the block after #twice" do
          expect(@double).to receive(:foo).twice { add_call }

          @double.foo
          @double.foo

          expect(@calls).to eq 2
        end

        it "calls the block after #times" do
          expect(@double).to receive(:foo).exactly(10).times { add_call }

          (1..10).each { @double.foo }

          expect(@calls).to eq 10
        end

        it "calls the block after #ordered" do
          expect(@double).to receive(:foo).ordered { add_call }
          expect(@double).to receive(:bar).ordered { add_call }

          @double.foo
          @double.bar

          expect(@calls).to eq 2
        end
      end

      describe 'string representation generated by #to_s' do
        it 'does not contain < because that might lead to invalid HTML in some situations' do
          dbl = double("Dog")
          valid_html_str = "#{dbl}"
          expect(valid_html_str).not_to include('<')
        end
      end

      describe "#to_str", :unless => RUBY_VERSION == '1.9.2' do
        it "should not respond to #to_str to avoid being coerced to strings by the runtime" do
          dbl = double("Foo")
          expect { dbl.to_str }.to raise_error(
            RSpec::Mocks::MockExpectationError,
            '#<Double "Foo"> received unexpected message :to_str with (no args)')
        end
      end

      describe "double created with no name" do
        it "does not use a name in a failure message" do
          dbl = double
          expect { dbl.foo }.to raise_error.with_message(a_string_including("#<Double (anonymous)> received"))
        end

        it "does respond to initially stubbed methods" do
          dbl = double(:foo => "woo", :bar => "car")
          expect(dbl.foo).to eq "woo"
          expect(dbl.bar).to eq "car"
        end
      end

      describe "==" do
        it "sends '== self' to the comparison object" do
          first = double('first')
          second = double('second')

          expect(first).to receive(:==).with(second)
          second == first
        end
      end

      describe "with" do
        before { @double = double('double') }
        context "with args" do
          context "with matching args" do
            it "passes" do
              expect(@double).to receive(:foo).with('bar')
              @double.foo('bar')
            end
          end

          context "with non-matching args" do
            it "fails" do
              expect(@double).to receive(:foo).with('bar')
              expect do
                @double.foo('baz')
              end.to fail
              reset @double
            end
          end

          context "with non-matching doubles" do
            it "fails" do
              d1 = double('1')
              d2 = double('2')
              expect(@double).to receive(:foo).with(d1)
              expect do
                @double.foo(d2)
              end.to fail
              reset @double
            end
          end

          context "with non-matching doubles as_null_object" do
            it "fails" do
              d1 = double('1').as_null_object
              d2 = double('2').as_null_object
              expect(@double).to receive(:foo).with(d1)
              expect do
                @double.foo(d2)
              end.to fail
              reset @double
            end
          end
        end

        context "with a block" do
          context "with matching args" do
            it "returns the result of the block" do
              expect(@double).to receive(:foo).with('bar') { 'baz' }
              expect(@double.foo('bar')).to eq('baz')
            end
          end

          context "with non-matching args" do
            it "fails" do
              expect(@double).to receive(:foo).with('bar') { 'baz' }
              expect do
                expect(@double.foo('wrong')).to eq('baz')
              end.to raise_error(/received :foo with unexpected arguments/)
              reset @double
            end
          end
        end
      end
    end
  end
end
