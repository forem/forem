module RSpec
  module Mocks
    RSpec.describe Matchers::Receive do
      include_context "with syntax", :expect

      describe "expectations/allowances on any instance recorders" do
        include_context "with syntax", [:expect, :should]

        it "warns about allow(Klass.any_instance).to receive..." do
          expect(RSpec).to receive(:warning).with(/allow.*any_instance.*is probably not what you meant.*allow_any_instance_of.*instead/)
          allow(Object.any_instance).to receive(:foo)
        end

        it "includes the correct call site in the allow warning" do
          expect_warning_with_call_site(__FILE__, __LINE__ + 1)
          allow(Object.any_instance).to receive(:foo)
        end

        it "warns about expect(Klass.any_instance).to receive..." do
          expect(RSpec).to receive(:warning).with(/expect.*any_instance.*is probably not what you meant.*expect_any_instance_of.*instead/)
          any_instance_proxy = Object.any_instance
          expect(any_instance_proxy).to receive(:foo)
          any_instance_proxy.foo
        end

        it "includes the correct call site in the expect warning" do
          any_instance_proxy = Object.any_instance
          expect_warning_with_call_site(__FILE__, __LINE__ + 1)
          expect(any_instance_proxy).to receive(:foo)
          any_instance_proxy.foo
        end
      end

      shared_examples "a receive matcher" do |*options|
        it 'allows the caller to configure how the subject responds' do
          wrapped.to receive(:foo).and_return(5)
          expect(receiver.foo).to eq(5)
        end

        it 'allows the caller to constrain the received arguments' do
          wrapped.to receive(:foo).with(:a)
          receiver.foo(:a)

          expect {
            receiver.foo(:b)
          }.to raise_error(/received :foo with unexpected arguments/)
        end

        it 'allows the caller to constrain the received arguments by matcher' do
          wrapped.to receive(:foo).with an_instance_of Float
          expect {
            receiver.foo(1)
          }.to raise_error(/expected.*\(an instance of Float\)/)
          receiver.foo(1.1)
        end

        context 'without yielding receiver' do
          # when `yield_receiver_to_any_instance_implementation_blocks` is `true`
          # the block arguments are different for `expect` and `expect_any_instance_of`
          around do |example|
             previous_value = RSpec::Mocks.configuration.yield_receiver_to_any_instance_implementation_blocks?
             RSpec::Mocks.configuration.yield_receiver_to_any_instance_implementation_blocks = false
             example.run
             RSpec::Mocks.configuration.yield_receiver_to_any_instance_implementation_blocks = previous_value
          end

          it 'allows a `do...end` block implementation to be provided' do
            wrapped.to receive(:foo) do
              4
            end

            expect(receiver.foo).to eq(4)
          end

          if RSpec::Support::RubyFeatures.kw_args_supported?
            binding.eval(<<-RUBY, __FILE__, __LINE__)
            it 'allows a `do...end` block implementation with keyword args to be provided' do
              wrapped.to receive(:foo) do |**kwargs|
                kwargs[:kw]
              end

              expect(receiver.foo(kw: :arg)).to eq(:arg)
            end

            it 'allows a `do...end` block implementation with optional keyword args to be provided' do
              wrapped.to receive(:foo) do |kw: :arg|
                kw
              end

              expect(receiver.foo(kw: 1)).to eq(1)
            end

            it 'allows a `do...end` block implementation with optional keyword args to be provided' do
              wrapped.to receive(:foo) do |kw: :arg|
                kw
              end

              expect(receiver.foo).to eq(:arg)
            end
            RUBY
          end

          if RSpec::Support::RubyFeatures.required_kw_args_supported?
            binding.eval(<<-RUBY, __FILE__, __LINE__)
            it 'allows a `do...end` block implementation with required keyword args' do
              wrapped.to receive(:foo) do |kw:|
                kw
              end

              expect(receiver.foo(kw: :arg)).to eq(:arg)
            end
            RUBY
          end
        end

        it 'allows chaining off a `do...end` block implementation to be provided' do
          wrapped.to receive(:foo) do
            4
          end.and_return(6)

          expect(receiver.foo).to eq(6)
        end

        it 'allows a `{ ... }` block implementation to be provided' do
          wrapped.to receive(:foo) { 5 }
          expect(receiver.foo).to eq(5)
        end

        it 'gives precedence to a `{ ... }` block when both forms are provided ' \
           'since that form actually binds to `receive`' do
          wrapped.to receive(:foo) { :curly } do
            :do_end
          end

          expect(receiver.foo).to eq(:curly)
        end

        it 'does not support other matchers', :unless => options.include?(:allow_other_matchers) do
          expect {
            wrapped.to eq(3)
          }.to raise_error(UnsupportedMatcherError)
        end

        it 'does support inherited matchers', :unless => options.include?(:allow_other_matchers) do
          receive_foo = Class.new(RSpec::Mocks::Matchers::Receive).new(:foo, nil)
          wrapped.to receive_foo
          receiver.foo
        end

        it 'does not get confused by messages being passed as strings and symbols' do
          wrapped.to receive(:foo).with(1) { :a }
          wrapped.to receive("foo").with(2) { :b }

          expect(receiver.foo(1)).to eq(:a)
          expect(receiver.foo(2)).to eq(:b)
        end

        it 'allows do...end blocks to be passed to the fluent interface methods without getting a warning' do
          expect(RSpec).not_to receive(:warning)

          wrapped.to receive(:foo).with(1) do
            :a
          end

          expect(receiver.foo(1)).to eq(:a)
        end

        it 'makes { } blocks trump do...end blocks when passed to a fluent interface method' do
          wrapped.to receive(:foo).with(1) { :curly } do
            :do_end
          end

          expect(receiver.foo(1)).to eq(:curly)
        end
      end

      shared_examples "an expect syntax allowance" do |*options|
        it_behaves_like "a receive matcher", *options

        it 'does not expect the message to be received' do
          wrapped.to receive(:foo)
          expect { verify_all }.not_to raise_error
        end
      end

      shared_examples "an expect syntax negative allowance" do
        it 'is disabled since this expression is confusing' do
          expect {
            wrapped.not_to receive(:foo)
          }.to raise_error(/not_to receive` is not supported/)

          expect {
            wrapped.to_not receive(:foo)
          }.to raise_error(/to_not receive` is not supported/)
        end
      end

      shared_examples "an expect syntax expectation" do |*options|
        it_behaves_like "a receive matcher", *options

        it 'sets up a message expectation that passes if the message is received' do
          wrapped.to receive(:foo)
          receiver.foo
          verify_all
        end

        it 'sets up a message expectation that fails if the message is not received' do
          wrapped.to receive(:foo)

          expect {
            verify_all
          }.to fail
        end

        it "reports the line number of expectation of unreceived message", :pending => options.include?(:does_not_report_line_num) do
          expected_error_line = __LINE__; wrapped.to receive(:foo)

          expect {
            verify_all
          }.to raise_error { |e|
            expect(e.backtrace.first).to match(/#{File.basename(__FILE__)}:#{expected_error_line}/)
          }
        end

        it "provides a useful matcher description" do
          matcher = receive(:foo).with(:bar).once
          wrapped.to matcher
          receiver.foo(:bar)

          expect(matcher.description).to start_with("receive foo")
        end
      end

      shared_examples "an expect syntax negative expectation" do
        it 'sets up a negative message expectation that passes if the message is not received' do
          wrapped.not_to receive(:foo)
          verify_all
        end

        it 'sets up a negative message expectation that fails if the message is received' do
          wrapped.not_to receive(:foo)

          expect_fast_failure_from(receiver, /expected: 0 times.*received: 1 time/m) do
            receiver.foo
          end
        end

        it 'supports `to_not` as an alias for `not_to`' do
          wrapped.to_not receive(:foo)

          expect_fast_failure_from(receiver, /expected: 0 times.*received: 1 time/m) do
            receiver.foo
          end
        end

        it 'allows the caller to constrain the received arguments' do
          wrapped.not_to receive(:foo).with(:a)
          def receiver.method_missing(*); end # a poor man's stub...

          expect {
            receiver.foo(:b)
          }.not_to raise_error

          expect_fast_failure_from(receiver, /expected: 0 times.*received: 1 time/m) do
            receiver.foo(:a)
          end
        end

        it 'prevents confusing double-negative expressions involving `never`' do
          expect {
            wrapped.not_to receive(:foo).never
          }.to raise_error(/trying to negate it again/)

          expect {
            wrapped.to_not receive(:foo).never
          }.to raise_error(/trying to negate it again/)
        end
      end

      shared_examples "resets partial mocks cleanly" do
        let(:klass)  { Struct.new(:foo) }
        let(:object) { klass.new :bar }

        it "removes the method double" do
          target.to receive(:foo).and_return(:baz)
          expect { reset object }.to change { object.foo }.from(:baz).to(:bar)
        end

        context "on a frozen object" do
          it "warns about being unable to remove the method double" do
            target.to receive(:foo).and_return(:baz)
            expect_warning_without_call_site(/rspec-mocks was unable to restore the original `foo` method on #{object.inspect}/)
            object.freeze
            reset object
          end

          it "includes the spec location in the warning" do
            line = __LINE__ - 1
            target.to receive(:foo).and_return(:baz)
            expect_warning_without_call_site(/#{RSpec::Core::Metadata.relative_path(__FILE__)}:#{line}/)
            object.freeze
            reset object
          end
        end
      end

      shared_examples "resets partial mocks of any instance cleanly" do
        let(:klass)  { Struct.new(:foo) }
        let(:object) { klass.new :bar }

        it "removes the method double" do
          target.to receive(:foo).and_return(:baz)
          expect {
            verify_all
          }.to change { object.foo }.from(:baz).to(:bar)
        end
      end

      describe "allow(...).to receive" do
        it_behaves_like "an expect syntax allowance" do
          let(:receiver) { double }
          let(:wrapped)  { allow(receiver) }
        end
        it_behaves_like "resets partial mocks cleanly" do
          let(:target) { allow(object) }
        end

        context 'ordered with receive counts' do
          specify 'is not supported' do
            a_dbl = double
            expect_warning_with_call_site(__FILE__, __LINE__ + 1)
            allow(a_dbl).to receive(:one).ordered
          end
        end

        context 'on a class method, from a class with subclasses' do
          let(:superclass)     { Class.new { def self.foo; "foo"; end }}
          let(:subclass_redef) { Class.new(superclass) { def self.foo; ".foo."; end }}
          let(:subclass_deleg) { Class.new(superclass) { def self.foo; super.upcase; end }}
          let(:subclass_asis)  { Class.new(superclass) }

          context 'if the method is redefined in the subclass' do
            it 'does not stub the method in the subclass' do
              allow(superclass).to receive(:foo) { "foo!!" }
              expect(superclass.foo).to eq "foo!!"
              expect(subclass_redef.foo).to eq ".foo."
            end
          end

          context 'if the method is not redefined in the subclass' do
            it 'stubs the method in the subclass' do
              allow(superclass).to receive(:foo) { "foo!!" }
              expect(superclass.foo).to eq "foo!!"
              expect(subclass_asis.foo).to eq "foo!!"
            end
          end

          it 'creates stub which can be called using `super` in a subclass' do
            allow(superclass).to receive(:foo) { "foo!!" }
            expect(subclass_deleg.foo).to eq "FOO!!"
          end

          it 'can stub the same method simultaneously in the superclass and subclasses' do
            allow(subclass_redef).to receive(:foo) { "__foo__" }
            allow(superclass).to     receive(:foo) { "foo!!" }
            allow(subclass_deleg).to receive(:foo) { "$$foo$$" }

            expect(subclass_redef.foo).to eq "__foo__"
            expect(superclass.foo).to     eq "foo!!"
            expect(subclass_deleg.foo).to eq "$$foo$$"
          end
        end
      end

      describe "allow(...).not_to receive" do
        it_behaves_like "an expect syntax negative allowance" do
          let(:wrapped) { allow(double) }
        end
      end

      describe "allow_any_instance_of(...).to receive" do
        it_behaves_like "an expect syntax allowance" do
          let(:klass)    { Class.new }
          let(:wrapped)  { allow_any_instance_of(klass) }
          let(:receiver) { klass.new }
        end

        it_behaves_like "resets partial mocks of any instance cleanly" do
          let(:target) { allow_any_instance_of(klass) }
        end
      end

      describe "allow_any_instance_of(...).not_to receive" do
        it_behaves_like "an expect syntax negative allowance" do
          let(:wrapped) { allow_any_instance_of(Class.new) }
        end
      end

      describe "expect(...).to receive" do
        it_behaves_like "an expect syntax expectation", :allow_other_matchers do
          let(:receiver) { double }
          let(:wrapped)  { expect(receiver) }

          context "when a message is not received" do
            it 'sets up a message expectation that formats argument matchers correctly' do
              wrapped.to receive(:foo).with an_instance_of Float
              expect { verify_all }.to(
                raise_error(/expected: 1 time with arguments: \(an instance of Float\)\n\s+received: 0 times$/)
              )
            end
          end

          context "when a message is received the wrong number of times" do
            it "sets up a message expectation that formats argument matchers correctly" do
              wrapped.to receive(:foo).with(anything, hash_including(:bar => anything))

              receiver.foo(1, :bar => 2)
              receiver.foo(1, :bar => 3)

              expect { verify_all }.to(
                raise_error(/received: 2 times with arguments: \(anything, hash_including\(:bar=>"anything"\)\)$/)
              )
            end
          end
        end
        it_behaves_like "resets partial mocks cleanly" do
          let(:target) { expect(object) }
        end

        context "ordered with receive counts" do
          let(:dbl) { double(:one => 1, :two => 2) }

          it "passes with exact receive counts when the ordering is correct" do
            expect(dbl).to receive(:one).twice.ordered
            expect(dbl).to receive(:two).once.ordered

            dbl.one
            dbl.one
            dbl.two
          end

          it "fails with exact receive counts when the ordering is incorrect" do
            expect {
              expect(dbl).to receive(:one).twice.ordered
              expect(dbl).to receive(:two).once.ordered

              dbl.one
              dbl.two
              dbl.one
            }.to raise_error(/out of order/)

            reset_all
          end

          it "passes with at least when the ordering is correct" do
            expect(dbl).to receive(:one).at_least(2).times.ordered
            expect(dbl).to receive(:two).once.ordered

            dbl.one
            dbl.one
            dbl.one
            dbl.two
          end

          it "fails with at least when the ordering is incorrect", :ordered_and_vague_counts_unsupported do
            expect {
              expect(dbl).to receive(:one).at_least(2).times.ordered
              expect(dbl).to receive(:two).once.ordered

              dbl.one
              dbl.two
            }.to fail

            reset_all
          end

          it "passes with at most when the ordering is correct" do
            expect(dbl).to receive(:one).at_most(2).times.ordered
            expect(dbl).to receive(:two).once.ordered

            dbl.one
            dbl.two
          end

          it "fails with at most when the ordering is incorrect", :ordered_and_vague_counts_unsupported do
            expect {
              expect(dbl).to receive(:one).at_most(2).times.ordered
              expect(dbl).to receive(:two).once.ordered

              dbl.one
              dbl.one
              dbl.one
              dbl.two
            }.to fail

            reset_all
          end

          it 'does not result in infinite recursion when `respond_to?` is stubbed' do
            # Setting a method expectation causes the method to be proxied
            # RSpec may call #respond_to? when processing a failed expectation
            # If those internal calls go to the proxied method, that could
            #   result in another failed expectation error, causing infinite loop
            expect {
              obj = Object.new
              expect(obj).to receive(:respond_to?).with('something highly unlikely')
              obj.respond_to?(:not_what_we_wanted)
            }.to raise_error(/received :respond_to\? with unexpected arguments/)
            reset_all
          end
        end
      end

      describe "expect_any_instance_of(...).to receive" do
        it_behaves_like "an expect syntax expectation", :does_not_report_line_num do
          let(:klass)    { Class.new }
          let(:wrapped)  { expect_any_instance_of(klass) }
          let(:receiver) { klass.new }

          it 'sets up a message expectation that formats argument matchers correctly' do
            wrapped.to receive(:foo).with an_instance_of Float
            expect { verify_all }.to raise_error(/should have received the following message\(s\) but didn't/)
          end
        end
        it_behaves_like "resets partial mocks of any instance cleanly" do
          let(:target) { expect_any_instance_of(klass) }
        end
      end

      describe "expect(...).not_to receive" do
        it_behaves_like "an expect syntax negative expectation" do
          let(:receiver) { double }
          let(:wrapped)  { expect(receiver) }
        end
      end

      describe "expect_any_instance_of(...).not_to receive" do
        it_behaves_like "an expect syntax negative expectation" do
          let(:klass)    { Class.new }
          let(:wrapped)  { expect_any_instance_of(klass) }
          let(:receiver) { klass.new }
        end
      end

      it 'has a description before being matched' do
        matcher = receive(:foo)
        expect(matcher.description).to eq("receive foo")
      end

      shared_examples "using rspec-mocks in another test framework" do
        it 'can use the `expect` syntax' do
          dbl = double

          framework.new.instance_exec do
            expect(dbl).to receive(:foo).and_return(3)
          end

          expect(dbl.foo).to eq(3)
        end

        it 'expects the method to be called when `expect` is used' do
          dbl = double

          framework.new.instance_exec do
            expect(dbl).to receive(:foo)
          end

          expect { verify dbl }.to fail
        end

        it 'supports `expect(...).not_to receive`' do
          expect_fast_failure_from(double) do |dbl|
            framework.new.instance_exec do
              expect(dbl).not_to receive(:foo)
            end

            dbl.foo
          end
        end

        it 'supports `expect(...).to_not receive`' do
          expect_fast_failure_from(double) do |dbl|
            framework.new.instance_exec do
              expect(dbl).to_not receive(:foo)
            end

            dbl.foo
          end
        end
      end

      context "when used in a test framework without rspec-expectations" do
        let(:framework) do
          Class.new do
            include RSpec::Mocks::ExampleMethods

            def eq(_)
              double("MyMatcher")
            end
          end
        end

        it_behaves_like "using rspec-mocks in another test framework"

        it 'cannot use `expect` with another matcher' do
          expect {
            framework.new.instance_exec do
              expect(3).to eq(3)
            end
          }.to raise_error(/only the `receive`, `have_received` and `receive_messages` matchers are supported with `expect\(...\).to`/)
        end

        it 'can toggle the available syntax' do
          expect(framework.new).to respond_to(:expect)
          RSpec::Mocks.configuration.syntax = :should
          expect(framework.new).not_to respond_to(:expect)
          RSpec::Mocks.configuration.syntax = :expect
          expect(framework.new).to respond_to(:expect)
        end

        after { RSpec::Mocks.configuration.syntax = :expect }
      end

      context "when rspec-expectations is included in the test framework first" do
        before do
          # the examples here assume `expect` is define in RSpec::Matchers...
          expect(RSpec::Matchers.method_defined?(:expect)).to be_truthy
        end

        let(:framework) do
          Class.new do
            include RSpec::Matchers
            include RSpec::Mocks::ExampleMethods
          end
        end

        it_behaves_like "using rspec-mocks in another test framework"

        it 'can use `expect` with any matcher' do
          framework.new.instance_exec do
            expect(3).to eq(3)
          end
        end
      end

      context "when rspec-expectations is included in the test framework last" do
        before do
          # the examples here assume `expect` is define in RSpec::Matchers...
          expect(RSpec::Matchers.method_defined?(:expect)).to be_truthy
        end

        let(:framework) do
          Class.new do
            include RSpec::Mocks::ExampleMethods
            include RSpec::Matchers
          end
        end

        it_behaves_like "using rspec-mocks in another test framework"

        it 'can use `expect` with any matcher' do
          framework.new.instance_exec do
            expect(3).to eq(3)
          end
        end
      end
    end
  end
end
