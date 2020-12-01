require 'delegate'

module AnyInstanceSpec
  class GrandparentClass
    def foo(_a)
      'bar'
    end

    def grandparent_method
      1
    end
  end

  class ParentClass < GrandparentClass
    def foo
      super(:a)
    end

    def caller_of_parent_aliased_method
      parent_aliased_method
    end

    alias parent_aliased_method grandparent_method
  end

  class ChildClass < ParentClass
  end
end

module RSpec
  module Mocks
    RSpec.describe "#any_instance" do
      class CustomErrorForAnyInstanceSpec < StandardError; end

      let(:klass) do
        Class.new do
          def existing_method; :existing_method_return_value; end
          def existing_method_with_arguments(_a, _b=nil); :existing_method_with_arguments_return_value; end
          def another_existing_method; end
        private
          def private_method; :private_method_return_value; end
        end
      end
      let(:existing_method_return_value) { :existing_method_return_value }

      context "chain" do
        it "yields the value specified" do
          allow_any_instance_of(klass).to receive(:foo).and_yield(1).and_yield(2)
          expect { |b| klass.new.foo(&b) }.to yield_successive_args(1, 2)
        end
      end

      context "invocation order" do
        context "when stubbing" do
          it "raises an error if 'with' follows 'and_return'" do
            expect { allow_any_instance_of(klass).to receive(:foo).and_return(1).with("1") }.to raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_raise'" do
            expect { allow_any_instance_of(klass).to receive(:foo).and_raise(1).with("1") }.to raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_yield'" do
            expect { allow_any_instance_of(klass).to receive(:foo).and_yield(1).with("1") }.to raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_throw'" do
            expect { allow_any_instance_of(klass).to receive(:foo).and_throw(:ball).with("football") }.to raise_error(NoMethodError)
          end

          it "allows chaining 'and_yield'" do
            allow_any_instance_of(klass).to receive(:foo).and_yield(1).and_yield(2).and_yield(3)
            expect { |b| klass.new.foo(&b) }.to yield_successive_args(1, 2, 3)
          end
        end

        context "when setting a message expectation" do
          it "raises an error if 'with' follows 'and_return'" do
            pending "see Github issue #42"
            expect { expect_any_instance_of(klass).to receive(:foo).and_return(1).with("1") }.to raise_error(NoMethodError)
          end

          it "raises an error if 'with' follows 'and_raise'" do
            pending "see Github issue #42"
            expect { expect_any_instance_of(klass).to receive(:foo).and_raise(1).with("1") }.to raise_error(NoMethodError)
          end
        end
      end

      context "when stubbing" do
        it "does not suppress an exception when a method that doesn't exist is invoked" do
          allow_any_instance_of(klass).to receive(:foo)
          expect { klass.new.bar }.to raise_error(NoMethodError)
        end

        context 'multiple methods' do
          it "allows multiple methods to be stubbed in a single invocation" do
            allow_any_instance_of(klass).to receive_messages(:foo => 'foo', :bar => 'bar')
            instance = klass.new
            expect(instance.foo).to eq('foo')
            expect(instance.bar).to eq('bar')
          end

          context "allows a chain of methods to be stubbed using #receive_message_chain" do
            example "given symbols representing the methods" do
              allow_any_instance_of(klass).to receive_message_chain(:one, :two, :three).and_return(:four)
              expect(klass.new.one.two.three).to eq(:four)
            end

            example "given a hash as the last argument uses the value as the expected return value" do
              allow_any_instance_of(klass).to receive_message_chain(:one, :two, :three => :four)
              expect(klass.new.one.two.three).to eq(:four)
            end

            example "given a string of '.' separated method names representing the chain" do
              allow_any_instance_of(klass).to receive_message_chain('one.two.three').and_return(:four)
              expect(klass.new.one.two.three).to eq(:four)
            end

            it "can constrain the return value by the argument to the last call" do
              allow_any_instance_of(klass).to receive_message_chain(:one, :plus).with(1) { 2 }
              allow_any_instance_of(klass).to receive_message_chain(:one, :plus).with(2) { 3 }
              expect(klass.new.one.plus(1)).to eq(2)
              expect(klass.new.one.plus(2)).to eq(3)
            end

            it 'can use a chain of methods to perform an expectation' do
              expect_any_instance_of(klass).to receive_message_chain('message1.message2').with('some args')
              klass.new.message1.message2('some args')
            end
          end
        end

        context "behaves as 'every instance'" do
          let(:super_class) { Class.new { def foo; 'bar'; end } }
          let(:sub_class)   { Class.new(super_class) }

          it "stubs every instance in the spec" do
            allow_any_instance_of(klass).to receive(:foo).and_return(result = Object.new)
            expect(klass.new.foo).to eq(result)
            expect(klass.new.foo).to eq(result)
          end

          it "stubs instance created before any_instance was called" do
            instance = klass.new
            allow_any_instance_of(klass).to receive(:foo).and_return(result = Object.new)
            expect(instance.foo).to eq(result)
          end

          it 'handles freeze and duplication correctly' do
            allow_any_instance_of(String).to receive(:any_method)

            foo = 'foo'.freeze
            expect(foo.dup.concat 'bar').to eq 'foobar'
          end

          it 'handles stubbing on super and subclasses' do
            allow_any_instance_of(super_class).to receive(:foo)
            allow_any_instance_of(sub_class).to receive(:foo).and_return('baz')
            expect(sub_class.new.foo).to eq('baz')
          end

          it 'handles method restoration on subclasses' do
            allow_any_instance_of(super_class).to receive(:foo)
            allow_any_instance_of(sub_class).to receive(:foo)
            allow_any_instance_of(sub_class).to receive(:foo).and_call_original
            expect(sub_class.new.foo).to eq("bar")
          end
        end

        context "when the class has a prepended module", :if => Support::RubyFeatures.module_prepends_supported? do
          it 'allows stubbing a method that is not defined on the prepended module' do
            klass.class_eval { prepend Module.new { def other; end } }
            allow_any_instance_of(klass).to receive(:foo).and_return(45)

            expect(klass.new.foo).to eq(45)
          end

          it 'prevents stubbing a method that is defined on the prepended module' do
            klass.class_eval { prepend Module.new { def foo; end } }

            expect {
              allow_any_instance_of(klass).to receive(:foo).and_return(45)
            }.to fail_with(/prepended module/)
          end

          it 'allows stubbing a chain starting with a method that is not defined on the prepended module' do
            klass.class_eval { prepend Module.new { def other; end } }
            allow_any_instance_of(klass).to receive_message_chain(:foo, :bar).and_return(45)

            expect(klass.new.foo.bar).to eq(45)
          end

          it 'prevents stubbing a chain starting with a method that is defined on the prepended module' do
            klass.class_eval { prepend Module.new { def foo; end } }

            expect {
              allow_any_instance_of(klass).to receive_message_chain(:foo, :bar).and_return(45)
            }.to fail_with(/prepended module/)
          end
        end

        context 'aliased methods' do
          it 'tracks aliased method calls' do
            instance = AnyInstanceSpec::ParentClass.new
            expect_any_instance_of(AnyInstanceSpec::ParentClass).to receive(:parent_aliased_method).with(no_args).and_return(2)
            expect(instance.caller_of_parent_aliased_method).to eq 2

            reset_all
            expect(instance.caller_of_parent_aliased_method).to eq 1
          end
        end

        context "with argument matching" do
          before do
            allow_any_instance_of(klass).to receive(:foo).with(:param_one, :param_two).and_return(:result_one)
            allow_any_instance_of(klass).to receive(:foo).with(:param_three, :param_four).and_return(:result_two)
          end

          it "returns the stubbed value when arguments match" do
            instance = klass.new
            expect(instance.foo(:param_one, :param_two)).to eq(:result_one)
            expect(instance.foo(:param_three, :param_four)).to eq(:result_two)
          end

          it "fails the spec with an expectation error when the arguments do not match" do
            expect do
              klass.new.foo(:param_one, :param_three)
            end.to fail
          end
        end

        context "with multiple stubs" do
          before do
            allow_any_instance_of(klass).to receive(:foo).and_return(1)
            allow_any_instance_of(klass).to receive(:bar).and_return(2)
          end

          it "stubs a method" do
            instance = klass.new
            expect(instance.foo).to eq(1)
            expect(instance.bar).to eq(2)
          end

          it "returns the same value for calls on different instances" do
            expect(klass.new.foo).to eq(klass.new.foo)
            expect(klass.new.bar).to eq(klass.new.bar)
          end
        end

        context "with #and_return" do
          it "can stub a method that doesn't exist" do
            allow_any_instance_of(klass).to receive(:foo).and_return(1)
            expect(klass.new.foo).to eq(1)
          end

          it "can stub a method that exists" do
            allow_any_instance_of(klass).to receive(:existing_method).and_return(1)
            expect(klass.new.existing_method).to eq(1)
          end

          it "returns the same object for calls on different instances" do
            return_value = Object.new
            allow_any_instance_of(klass).to receive(:foo).and_return(return_value)
            expect(klass.new.foo).to be(return_value)
            expect(klass.new.foo).to be(return_value)
          end

          it "can change how instances responds in the middle of an example" do
            instance = klass.new

            allow_any_instance_of(klass).to receive(:foo).and_return(1)
            expect(instance.foo).to eq(1)
            allow_any_instance_of(klass).to receive(:foo).and_return(2)
            expect(instance.foo).to eq(2)
            allow_any_instance_of(klass).to receive(:foo).and_raise("boom")
            expect { instance.foo }.to raise_error("boom")
          end
        end

        context "with #and_yield" do
          it "yields the value specified" do
            yielded_value = Object.new
            allow_any_instance_of(klass).to receive(:foo).and_yield(yielded_value)
            expect { |b| klass.new.foo(&b) }.to yield_with_args(yielded_value)
          end
        end

        context 'with #and_call_original and competing #with' do
          let(:klass) { Struct.new(:a_method) }

          it 'can combine and_call_original, with, and_return' do
            allow_any_instance_of(klass).to receive(:a_method).and_call_original
            allow_any_instance_of(klass).to receive(:a_method).with(:arg).and_return('value')

            expect(klass.new('org').a_method).to eq 'org'
            expect(klass.new.a_method(:arg)).to  eq 'value'
          end
        end

        context "with #and_raise" do
          it "can stub a method that doesn't exist" do
            allow_any_instance_of(klass).to receive(:foo).and_raise(CustomErrorForAnyInstanceSpec)
            expect { klass.new.foo }.to raise_error(CustomErrorForAnyInstanceSpec)
          end

          it "can stub a method that exists" do
            allow_any_instance_of(klass).to receive(:existing_method).and_raise(CustomErrorForAnyInstanceSpec)
            expect { klass.new.existing_method }.to raise_error(CustomErrorForAnyInstanceSpec)
          end
        end

        context "with #and_throw" do
          it "can stub a method that doesn't exist" do
            allow_any_instance_of(klass).to receive(:foo).and_throw(:up)
            expect { klass.new.foo }.to throw_symbol(:up)
          end

          it "can stub a method that exists" do
            allow_any_instance_of(klass).to receive(:existing_method).and_throw(:up)
            expect { klass.new.existing_method }.to throw_symbol(:up)
          end
        end

        context "with a block" do
          it "stubs a method" do
            allow_any_instance_of(klass).to receive(:foo) { 1 }
            expect(klass.new.foo).to eq(1)
          end

          it "returns the same computed value for calls on different instances" do
            allow_any_instance_of(klass).to receive(:foo) { 1 + 2 }
            expect(klass.new.foo).to eq(klass.new.foo)
          end
        end

        context "when partially mocking objects" do
          let(:obj) { klass.new }

          it "resets partially mocked objects correctly" do
            allow_any_instance_of(klass).to receive(:existing_method).and_return("stubbed value")

            # Simply resetting the proxy doesn't work
            # what we need to have happen is
            # ::RSpec::Mocks.space.any_instance_recorder_for(klass).stop_all_observation!
            # but that is never invoked in ::
            expect {
              verify_all
            }.to(
              change { obj.existing_method }.from("stubbed value").to(:existing_method_return_value)
            )
          end
        end

        context "core ruby objects" do
          it "works uniformly across *everything*" do
            allow_any_instance_of(Object).to receive(:foo).and_return(1)
            expect(Object.new.foo).to eq(1)
          end

          it "works with the non-standard constructor []" do
            allow_any_instance_of(Array).to receive(:foo).and_return(1)
            expect([].foo).to eq(1)
          end

          it "works with the non-standard constructor {}" do
            allow_any_instance_of(Hash).to receive(:foo).and_return(1)
            expect({}.foo).to eq(1)
          end

          it "works with the non-standard constructor \"\"" do
            allow_any_instance_of(String).to receive(:foo).and_return(1)
            expect("".dup.foo).to eq(1)
          end

          it "works with the non-standard constructor \'\'" do
            allow_any_instance_of(String).to receive(:foo).and_return(1)
            expect(''.dup.foo).to eq(1)
          end

          it "works with the non-standard constructor module" do
            allow_any_instance_of(Module).to receive(:foo).and_return(1)
            module RSpec::SampleRspecTestModule; end
            expect(RSpec::SampleRspecTestModule.foo).to eq(1)
          end

          it "works with the non-standard constructor class" do
            allow_any_instance_of(Class).to receive(:foo).and_return(1)
            class RSpec::SampleRspecTestClass; end
            expect(RSpec::SampleRspecTestClass.foo).to eq(1)
          end
        end
      end

      context "unstubbing using `and_call_original`" do
        it "replaces the stubbed method with the original method" do
          allow_any_instance_of(klass).to receive(:existing_method)
          allow_any_instance_of(klass).to receive(:existing_method).and_call_original
          expect(klass.new.existing_method).to eq(:existing_method_return_value)
        end

        it "removes all stubs with the supplied method name" do
          allow_any_instance_of(klass).to receive(:existing_method).with(1)
          allow_any_instance_of(klass).to receive(:existing_method).with(2)
          allow_any_instance_of(klass).to receive(:existing_method).and_call_original
          expect(klass.new.existing_method).to eq(:existing_method_return_value)
        end

        it "removes stubs even if they have already been invoked" do
          allow_any_instance_of(klass).to receive(:existing_method).and_return(:any_instance_value)
          obj = klass.new
          obj.existing_method
          allow_any_instance_of(klass).to receive(:existing_method).and_call_original

          expect(obj.existing_method).to eq(:existing_method_return_value)
        end

        it "removes stubs from sub class after invokation when super class was originally stubbed" do
          allow_any_instance_of(klass).to receive(:existing_method).and_return(:any_instance_value)
          obj = Class.new(klass).new
          expect(obj.existing_method).to eq(:any_instance_value)
          allow_any_instance_of(klass).to receive(:existing_method).and_call_original

          expect(obj.existing_method).to eq(:existing_method_return_value)
        end

        it "removes any stubs set directly on an instance" do
          allow_any_instance_of(klass).to receive(:existing_method).and_return(:any_instance_value)
          obj = klass.new
          allow(obj).to receive(:existing_method).and_return(:local_method)
          allow_any_instance_of(klass).to receive(:existing_method).and_call_original
          expect(obj.existing_method).to eq(:existing_method_return_value)
        end

        it "does not remove any expectations with the same method name" do
          expect_any_instance_of(klass).to receive(:existing_method_with_arguments).with(3).and_return(:three)
          allow_any_instance_of(klass).to receive(:existing_method_with_arguments).with(1)
          allow_any_instance_of(klass).to receive(:existing_method_with_arguments).with(2)
          allow_any_instance_of(klass).to receive(:existing_method_with_arguments).and_call_original
          expect(klass.new.existing_method_with_arguments(3)).to eq(:three)
        end

        it 'does not get confused about string vs symbol usage for the message' do
          allow_any_instance_of(klass).to receive(:existing_method) { :stubbed }
          allow_any_instance_of(klass).to receive("existing_method").and_call_original
          expect(klass.new.existing_method).to eq(:existing_method_return_value)
        end
      end

      context "expect_any_instance_of(...).not_to receive" do
        it "fails if the method is called" do
          expect_any_instance_of(klass).not_to receive(:existing_method)

          expect_fast_failure_from(klass.new) do |instance|
            instance.existing_method
          end
        end

        it "passes if no method is called" do
          expect { expect_any_instance_of(klass).not_to receive(:existing_method) }.to_not raise_error
        end

        it "passes if only a different method is called" do
          expect_any_instance_of(klass).not_to receive(:existing_method)
          expect { klass.new.another_existing_method }.to_not raise_error
        end

        it "affects previously stubbed instances" do
          instance = klass.new

          allow_any_instance_of(klass).to receive(:foo).and_return(1)
          expect(instance.foo).to eq(1)
          expect_any_instance_of(klass).not_to receive(:foo)

          expect_fast_failure_from(instance) do
            instance.foo
          end
        end

        context "with constraints" do
          it "fails if the method is called with the specified parameters" do
            expect_any_instance_of(klass).not_to receive(:existing_method_with_arguments).with(:argument_one, :argument_two)
            expect_fast_failure_from(klass.new) do |instance|
              instance.existing_method_with_arguments(:argument_one, :argument_two)
            end
          end

          it "passes if the method is called with different parameters" do
            expect_any_instance_of(klass).not_to receive(:existing_method_with_arguments).with(:argument_one, :argument_two)
            expect { klass.new.existing_method_with_arguments(:argument_three, :argument_four) }.to_not raise_error
          end
        end

        context 'when used in combination with should_receive' do
          it 'passes if only the expected message is received' do
            expect_any_instance_of(klass).to receive(:foo)
            expect_any_instance_of(klass).not_to receive(:bar)
            klass.new.foo
            verify_all
          end
        end

        it "prevents confusing double-negative expressions involving `never`" do
          expect {
            expect_any_instance_of(klass).not_to receive(:not_expected).never
          }.to raise_error(/trying to negate it again/)
        end
      end

      context "setting a message expectation" do
        let(:foo_expectation_error_message) { 'Exactly one instance should have received the following message(s) but didn\'t: foo' }
        let(:existing_method_expectation_error_message) { 'Exactly one instance should have received the following message(s) but didn\'t: existing_method' }

        it "handles inspect accessing expected methods" do
          klass.class_eval do
            def inspect
              "The contents of output: #{stdout}"
            end
          end

          expect_any_instance_of(klass).to receive(:stdout).at_least(:twice)
          expect do
            klass.new.stdout
            klass.new.stdout
          end.to raise_error(/The message 'stdout' was received by/)
          reset_all
        end

        it "affects previously stubbed instances" do
          instance = klass.new

          allow_any_instance_of(klass).to receive(:foo).and_return(1)
          expect(instance.foo).to eq(1)
          expect_any_instance_of(klass).to receive(:foo).with(2).and_return(2)
          expect(instance.foo(2)).to eq(2)
        end

        it "does not set the expectation on every instance" do
          # Setup an unrelated object of the same class that won't receive the expected message.
          allow('non-related object'.dup).to receive(:non_related_method)

          expect_any_instance_of(Object).to receive(:foo)
          'something'.dup.foo
        end

        it "does not modify the return value of stubs set on an instance" do
          expect_any_instance_of(Object).to receive(:foo).twice
          object = Object.new
          allow(object).to receive(:foo).and_return(3)
          expect(object.foo).to eq(3)
          expect(object.foo).to eq(3)
        end

        it "does not modify the return value of stubs set on an instance of a subclass" do
          subklass = Class.new(klass)
          subinstance = subklass.new
          allow_any_instance_of(klass).to receive(:foo).and_return(1)
          expect(subinstance.foo).to eq(1)
          expect_any_instance_of(klass).to receive(:foo).with(2).and_return(2)
          expect(subinstance.foo(2)).to eq(2)
        end

        it "properly notifies any instance recorders at multiple levels of hierarchy when a directly stubbed object receives a message" do
          subclass = Class.new(klass)
          instance = subclass.new

          expect_any_instance_of(klass).to receive(:msg_1)
          expect_any_instance_of(subclass).to receive(:msg_2)

          allow(instance).to receive_messages(:msg_1 => "a", :msg_2 => "b")

          expect(instance.msg_1).to eq("a")
          expect(instance.msg_2).to eq("b")
        end

        it "properly notifies any instance recorders when they are created after the object's mock proxy" do
          object = Object.new
          allow(object).to receive(:bar)
          expect_any_instance_of(Object).to receive(:foo).twice
          allow(object).to receive(:foo).and_return(3)
          expect(object.foo).to eq(3)
          expect(object.foo).to eq(3)
        end

        context "when the class has a prepended module", :if => Support::RubyFeatures.module_prepends_supported? do
          it 'allows mocking a method that is not defined on the prepended module' do
            klass.class_eval { prepend Module.new { def other; end } }
            expect_any_instance_of(klass).to receive(:foo).and_return(45)

            expect(klass.new.foo).to eq(45)
          end

          it 'prevents mocking a method that is defined on the prepended module' do
            klass.class_eval { prepend Module.new { def foo; end } }

            expect {
              expect_any_instance_of(klass).to receive(:foo).and_return(45)
            }.to fail_with(/prepended module/)
          end
        end

        context "when the class has an included module" do
          it 'allows mocking a method that is defined on the module' do
            mod = Module.new { def foo; end }
            klass.class_eval { include mod }
            expect_any_instance_of(mod).to receive(:foo).and_return(45)

            expect(klass.new.foo).to eq(45)
          end
        end

        context "when an instance has been directly stubbed" do
          it "fails when a second instance to receive the message" do
            expect_any_instance_of(klass).to receive(:foo)
            instance_1 = klass.new

            allow(instance_1).to receive(:foo).and_return(17)
            expect(instance_1.foo).to eq(17)

            expect {
              klass.new.foo
            }.to fail_with(/has already been received/)
          end
        end

        context "when argument matching is used and an instance has stubbed the message" do
          it "fails on verify if the arguments do not match" do
            expect_any_instance_of(klass).to receive(:foo).with(3)
            instance = klass.new
            allow(instance).to receive(:foo).and_return(2)

            expect(instance.foo(4)).to eq(2)
            expect { verify_all }.to fail
          end

          it "passes on verify if the arguments do match" do
            expect_any_instance_of(klass).to receive(:foo).with(3)
            instance = klass.new
            allow(instance).to receive(:foo).and_return(2)

            expect(instance.foo(3)).to eq(2)
            expect { verify_all }.not_to raise_error
          end
        end

        context "with an expectation is set on a method which does not exist" do
          it "returns the expected value" do
            expect_any_instance_of(klass).to receive(:foo).and_return(1)
            expect(klass.new.foo(1)).to eq(1)
          end

          it "fails if an instance is created but no invocation occurs" do
            expect do
              expect_any_instance_of(klass).to receive(:foo)
              klass.new
              verify_all
            end.to fail_with foo_expectation_error_message
          end

          it "fails if no instance is created" do
            expect do
              expect_any_instance_of(klass).to receive(:foo).and_return(1)
              verify_all
            end.to fail_with foo_expectation_error_message
          end

          it "fails if no instance is created and there are multiple expectations" do
            expect do
              expect_any_instance_of(klass).to receive(:foo)
              expect_any_instance_of(klass).to receive(:bar)
              verify_all
            end.to fail_with 'Exactly one instance should have received the following message(s) but didn\'t: bar, foo'
          end

          it "allows expectations on instances to take priority" do
            expect_any_instance_of(klass).to receive(:foo)
            klass.new.foo

            instance = klass.new
            expect(instance).to receive(:foo).and_return(result = Object.new)
            expect(instance.foo).to eq(result)
          end

          context "behaves as 'exactly one instance'" do
            it "passes if subsequent invocations do not receive that message" do
              expect_any_instance_of(klass).to receive(:foo)
              klass.new.foo
              klass.new
            end

            it "fails if the method is invoked on a second instance" do
              instance_one = klass.new
              instance_two = klass.new
              expect do
                expect_any_instance_of(klass).to receive(:foo)

                instance_one.foo
                instance_two.foo
              end.to fail_with(/The message 'foo' was received by .*#{instance_two.object_id}.* but has already been received by #{instance_one.inspect}/)
            end
          end

          context "normal expectations on the class object" do
            it "fail when unfulfilled" do
              expect do
                expect_any_instance_of(klass).to receive(:foo)
                expect(klass).to receive(:woot)
                klass.new.foo
                verify_all
              end.to(fail do |error|
                expect(error.message).not_to eq(existing_method_expectation_error_message)
              end)
            end

            it "pass when expectations are met" do
              expect_any_instance_of(klass).to receive(:foo)
              expect(klass).to receive(:woot).and_return(result = Object.new)
              klass.new.foo
              expect(klass.woot).to eq(result)
            end
          end
        end

        context "with an expectation is set on a method that exists" do
          it "returns the expected value" do
            expect_any_instance_of(klass).to receive(:existing_method).and_return(1)
            expect(klass.new.existing_method(1)).to eq(1)
          end

          it "fails if an instance is created but no invocation occurs" do
            expect do
              expect_any_instance_of(klass).to receive(:existing_method)
              klass.new
              verify_all
            end.to fail_with existing_method_expectation_error_message
          end

          it "fails if no instance is created" do
            expect do
              expect_any_instance_of(klass).to receive(:existing_method)
              verify_all
            end.to fail_with existing_method_expectation_error_message
          end

          it "fails if no instance is created and there are multiple expectations" do
            expect do
              expect_any_instance_of(klass).to receive(:existing_method)
              expect_any_instance_of(klass).to receive(:another_existing_method)
              verify_all
            end.to fail_with 'Exactly one instance should have received the following message(s) but didn\'t: another_existing_method, existing_method'
          end

          context "after any one instance has received a message" do
            it "passes if subsequent invocations do not receive that message" do
              expect_any_instance_of(klass).to receive(:existing_method)
              klass.new.existing_method
              klass.new
            end

            it "fails if the method is invoked on a second instance" do
              instance_one = klass.new
              instance_two = klass.new
              expect do
                expect_any_instance_of(klass).to receive(:existing_method)

                instance_one.existing_method
                instance_two.existing_method
              end.to fail_with(/The message 'existing_method' was received by .*#{instance_two.object_id}.* but has already been received by #{instance_one.inspect}/)
            end
          end
        end

        it 'works with a BasicObject subclass that mixes in Kernel', :if => defined?(BasicObject) do
          klazz = Class.new(BasicObject) do
            include ::Kernel
            def foo; end
          end

          expect_any_instance_of(klazz).to receive(:foo)
          klazz.new.foo
        end

        it 'works with a SimpleDelegator subclass', :if => (RUBY_VERSION.to_f > 1.8) do
          klazz = Class.new(SimpleDelegator) do
            def foo; end
          end

          expect_any_instance_of(klazz).to receive(:foo)
          klazz.new(Object.new).foo
        end

        context "with argument matching" do
          before do
            expect_any_instance_of(klass).to receive(:foo).with(:param_one, :param_two).and_return(:result_one)
            expect_any_instance_of(klass).to receive(:foo).with(:param_three, :param_four).and_return(:result_two)
          end

          it "returns the expected value when arguments match" do
            instance = klass.new
            expect(instance.foo(:param_one, :param_two)).to eq(:result_one)
            expect(instance.foo(:param_three, :param_four)).to eq(:result_two)
          end

          it "fails when the arguments match but different instances are used" do
            instances = Array.new(2) { klass.new }
            expect do
              expect(instances[0].foo(:param_one, :param_two)).to eq(:result_one)
              expect(instances[1].foo(:param_three, :param_four)).to eq(:result_two)
            end.to fail

            # ignore the fact that should_receive expectations were not met
            instances.each { |instance| reset instance }
          end

          it "is not affected by the invocation of existing methods on other instances" do
            expect(klass.new.existing_method_with_arguments(:param_one, :param_two)).to eq(:existing_method_with_arguments_return_value)
            instance = klass.new
            expect(instance.foo(:param_one, :param_two)).to eq(:result_one)
            expect(instance.foo(:param_three, :param_four)).to eq(:result_two)
          end

          it "fails when arguments do not match" do
            instance = klass.new
            expect do
              instance.foo(:param_one, :param_three)
            end.to fail

            # ignore the fact that should_receive expectations were not met
            reset instance
          end
        end

        context "message count" do
          context "the 'once' constraint" do
            it "passes for one invocation" do
              expect_any_instance_of(klass).to receive(:foo).once
              klass.new.foo
            end

            it "fails when no instances are declared" do
              expect do
                expect_any_instance_of(klass).to receive(:foo).once
                verify_all
              end.to fail_with foo_expectation_error_message
            end

            it "fails when an instance is declared but there are no invocations" do
              expect do
                expect_any_instance_of(klass).to receive(:foo).once
                klass.new
                verify_all
              end.to fail_with foo_expectation_error_message
            end

            it "fails for more than one invocation" do
              expect_any_instance_of(klass).to receive(:foo).once

              expect_fast_failure_from(klass.new) do |instance|
                2.times { instance.foo }
                verify instance
              end
            end
          end

          context "the 'twice' constraint" do
            it "passes for two invocations" do
              expect_any_instance_of(klass).to receive(:foo).twice
              instance = klass.new
              2.times { instance.foo }
            end

            it "fails for more than two invocations" do
              expect_any_instance_of(klass).to receive(:foo).twice

              expect_fast_failure_from(klass.new) do |instance|
                3.times { instance.foo }
                verify instance
              end
            end
          end

          context "the 'thrice' constraint" do
            it "passes for three invocations" do
              expect_any_instance_of(klass).to receive(:foo).thrice
              instance = klass.new
              3.times { instance.foo }
            end

            it "fails for more than three invocations" do
              expect_any_instance_of(klass).to receive(:foo).thrice
              expect_fast_failure_from(klass.new) do |instance|
                4.times { instance.foo }
                verify instance
              end
            end

            it "fails for less than three invocations" do
              expect do
                expect_any_instance_of(klass).to receive(:foo).thrice
                instance = klass.new
                2.times { instance.foo }
                verify instance
              end.to fail
            end
          end

          context "the 'exactly(n)' constraint" do
            describe "time alias" do
              it "passes for 1 invocation" do
                expect_any_instance_of(klass).to receive(:foo).exactly(1).time
                instance = klass.new
                instance.foo
              end

              it "fails for 2 invocations" do
                expect_any_instance_of(klass).to receive(:foo).exactly(1).time
                expect_fast_failure_from(klass.new) do |instance|
                  2.times { instance.foo }
                  verify instance
                end
              end
            end

            it "passes for n invocations where n = 3" do
              expect_any_instance_of(klass).to receive(:foo).exactly(3).times
              instance = klass.new
              3.times { instance.foo }
            end

            it "fails for n invocations where n < 3" do
              expect do
                expect_any_instance_of(klass).to receive(:foo).exactly(3).times
                instance = klass.new
                2.times { instance.foo }
                verify instance
              end.to fail
            end

            it "fails for n invocations where n > 3" do
              expect_any_instance_of(klass).to receive(:foo).exactly(3).times
              expect_fast_failure_from(klass.new) do |instance|
                4.times { instance.foo }
                verify instance
              end
            end
          end

          context "the 'at_least(n)' constraint" do
            it "passes for n invocations where n = 3" do
              expect_any_instance_of(klass).to receive(:foo).at_least(3).times
              instance = klass.new
              3.times { instance.foo }
            end

            it "fails for n invocations where n < 3" do
              expect do
                expect_any_instance_of(klass).to receive(:foo).at_least(3).times
                instance = klass.new
                2.times { instance.foo }
                verify instance
              end.to fail
            end

            it "passes for n invocations where n > 3" do
              expect_any_instance_of(klass).to receive(:foo).at_least(3).times
              instance = klass.new
              4.times { instance.foo }
            end
          end

          context "the 'at_most(n)' constraint" do
            it "passes for n invocations where n = 3" do
              expect_any_instance_of(klass).to receive(:foo).at_most(3).times
              instance = klass.new
              3.times { instance.foo }
            end

            it "passes for n invocations where n < 3" do
              expect_any_instance_of(klass).to receive(:foo).at_most(3).times
              instance = klass.new
              2.times { instance.foo }
            end

            it "fails for n invocations where n > 3" do
              expect_any_instance_of(klass).to receive(:foo).at_most(3).times
              expect_fast_failure_from(klass.new) do |instance|
                4.times { instance.foo }
                verify instance
              end
            end
          end

          context "the 'never' constraint" do
            it "passes for 0 invocations" do
              expect_any_instance_of(klass).to receive(:foo).never
              verify_all
            end

            it "fails on the first invocation" do
              expect_any_instance_of(klass).to receive(:foo).never
              expect_fast_failure_from(klass.new) do |instance|
                instance.foo
              end
            end

            context "when combined with other expectations" do
              it "passes when the other expectations are met" do
                expect_any_instance_of(klass).to receive(:foo).never
                expect_any_instance_of(klass).to receive(:existing_method).and_return(5)
                expect(klass.new.existing_method).to eq(5)
              end

              it "fails when the other expectations are not met" do
                expect do
                  expect_any_instance_of(klass).to receive(:foo).never
                  expect_any_instance_of(klass).to receive(:existing_method).and_return(5)
                  verify_all
                end.to fail_with existing_method_expectation_error_message
              end
            end
          end
        end
      end

      context "when resetting post-verification" do
        let(:space) { RSpec::Mocks.space }

        context "existing method" do
          before(:each) do
            RSpec::Mocks.space.any_instance_recorder_for(klass) # to force it to be tracked
          end

          context "with stubbing" do
            context "public methods" do
              before(:each) do
                allow_any_instance_of(klass).to receive(:existing_method).and_return(1)
                expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_truthy
              end

              it "restores the class to its original state after each example when no instance is created" do
                verify_all

                expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_falsey
                expect(klass.new.existing_method).to eq(existing_method_return_value)
              end

              it "restores the class to its original state after each example when one instance is created" do
                klass.new.existing_method

                verify_all

                expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_falsey
                expect(klass.new.existing_method).to eq(existing_method_return_value)
              end

              it "restores the class to its original state after each example when more than one instance is created" do
                klass.new.existing_method
                klass.new.existing_method

                verify_all

                expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_falsey
                expect(klass.new.existing_method).to eq(existing_method_return_value)
              end
            end

            context "private methods" do
              before :each do
                allow_any_instance_of(klass).to receive(:private_method).and_return(:something)

                verify_all
              end

              it "cleans up the backed up method" do
                expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_falsey
              end

              it "restores a stubbed private method after the spec is run" do
                expect(klass.private_method_defined?(:private_method)).to be_truthy
              end

              it "ensures that the restored method behaves as it originally did" do
                expect(klass.new.send(:private_method)).to eq(:private_method_return_value)
              end
            end
          end

          context "with expectations" do
            context "private methods" do
              before :each do
                expect_any_instance_of(klass).to receive(:private_method).and_return(:something)
                klass.new.private_method

                verify_all
              end

              it "cleans up the backed up method" do
                expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_falsey
              end

              it "restores a stubbed private method after the spec is run" do
                expect(klass.private_method_defined?(:private_method)).to be_truthy
              end

              it "ensures that the restored method behaves as it originally did" do
                expect(klass.new.send(:private_method)).to eq(:private_method_return_value)
              end
            end

            context "ensures that the subsequent specs do not see expectations set in previous specs" do
              context "when the instance created after the expectation is set" do
                it "first spec" do
                  expect_any_instance_of(klass).to receive(:existing_method).and_return(Object.new)
                  klass.new.existing_method
                end

                it "second spec" do
                  expect(klass.new.existing_method).to eq(existing_method_return_value)
                end
              end

              context "when the instance created before the expectation is set" do
                before :each do
                  @instance = klass.new
                end

                it "first spec" do
                  expect_any_instance_of(klass).to receive(:existing_method).and_return(Object.new)
                  @instance.existing_method
                end

                it "second spec" do
                  expect(@instance.existing_method).to eq(existing_method_return_value)
                end
              end
            end

            it "ensures that the next spec does not see that expectation" do
              expect_any_instance_of(klass).to receive(:existing_method).and_return(Object.new)
              klass.new.existing_method

              verify_all

              expect(klass.new.existing_method).to eq(existing_method_return_value)
            end
          end
        end

        context "with multiple calls to any_instance in the same example" do
          it "does not prevent the change from being rolled back" do
            allow_any_instance_of(klass).to receive(:existing_method).and_return(false)
            allow_any_instance_of(klass).to receive(:existing_method).and_return(true)

            verify_all
            expect(klass.new).to respond_to(:existing_method)
            expect(klass.new.existing_method).to eq(existing_method_return_value)
          end
        end

        it "adds an instance to the current space when stubbed method is invoked" do
          allow_any_instance_of(klass).to receive(:foo)
          instance = klass.new
          instance.foo
          expect(RSpec::Mocks.space.proxies.keys).to include(instance.object_id)
        end
      end

      context "passing the receiver to the implementation block" do
        context "when configured to pass the instance" do
          include_context 'with isolated configuration'
          before(:each) do
            RSpec::Mocks.configuration.yield_receiver_to_any_instance_implementation_blocks = true
          end

          describe "an any instance stub" do
            it "passes the instance as the first arg of the implementation block" do
              instance = klass.new

              expect { |b|
                expect_any_instance_of(klass).to receive(:bees).with(:sup, &b)
                instance.bees(:sup)
              }.to yield_with_args(instance, :sup)
            end

            it "does not pass the instance to and_call_original" do
              klazz = Class.new do
                def call(*args)
                  args.first
                end
              end
              expect_any_instance_of(klazz).to receive(:call).and_call_original
              instance = klazz.new
              expect(instance.call(:bees)).to be :bees
            end
          end

          describe "an any instance expectation" do
            it "doesn't effect with" do
              instance = klass.new
              expect_any_instance_of(klass).to receive(:bees).with(:sup)
              instance.bees(:sup)
            end

            it "passes the instance as the first arg of the implementation block" do
              instance = klass.new

              expect { |b|
                expect_any_instance_of(klass).to receive(:bees).with(:sup, &b)
                instance.bees(:sup)
              }.to yield_with_args(instance, :sup)
            end
          end
        end

        context "when configured not to pass the instance" do
          include_context 'with isolated configuration'
          before(:each) do
            RSpec::Mocks.configuration.yield_receiver_to_any_instance_implementation_blocks = false
          end

          describe "an any instance stub" do
            it "does not pass the instance to the implementation block" do
              instance = klass.new

              expect { |b|
                expect_any_instance_of(klass).to receive(:bees).with(:sup, &b)
                instance.bees(:sup)
              }.to yield_with_args(:sup)
            end

            it "does not cause with to fail when the instance is passed" do
              instance = klass.new
              expect_any_instance_of(klass).to receive(:bees).with(:faces)
              instance.bees(:faces)
            end
          end
        end
      end

      context 'when used in conjunction with a `dup`' do
        it "doesn't cause an infinite loop" do
          skip "This intermittently fails on JRuby" if RUBY_PLATFORM == 'java'

          allow_any_instance_of(Object).to receive(:some_method)
          o = Object.new
          o.some_method
          expect { o.dup.some_method }.to_not raise_error
        end

        it "doesn't bomb if the object doesn't support `dup`" do
          klazz = Class.new do
            undef_method :dup
          end
          allow_any_instance_of(klazz).to receive(:foo)
        end

        it "doesn't fail when dup accepts parameters" do
          klazz = Class.new do
            def dup(_)
            end
          end

          allow_any_instance_of(klazz).to receive(:foo)

          expect { klazz.new.dup('Dup dup dup') }.to_not raise_error
        end
      end

      context "when directed at a method defined on a superclass" do
        let(:sub_klass) { Class.new(klass) }

        it "stubs the method correctly" do
          allow_any_instance_of(klass).to receive(:existing_method).and_return("foo")
          expect(sub_klass.new.existing_method).to eq "foo"
        end

        it "mocks the method correctly" do
          instance_one = sub_klass.new
          instance_two = sub_klass.new
          expect do
            expect_any_instance_of(klass).to receive(:existing_method)
            instance_one.existing_method
            instance_two.existing_method
          end.to fail_with(/The message 'existing_method' was received by .*#{instance_two.object_id}.* but has already been received by #{instance_one.inspect}/)
        end
      end

      context "when a class overrides Object#method" do
        let(:http_request_class) { Struct.new(:method, :uri) }

        it "stubs the method correctly" do
          allow_any_instance_of(http_request_class).to receive(:existing_method).and_return("foo")
          expect(http_request_class.new.existing_method).to eq "foo"
        end

        it "mocks the method correctly" do
          expect_any_instance_of(http_request_class).to receive(:existing_method).and_return("foo")
          expect(http_request_class.new.existing_method).to eq "foo"
        end
      end

      context "when used after the test has finished" do
        it "restores the original behavior of a stubbed method" do
          allow_any_instance_of(klass).to receive(:existing_method).and_return(:stubbed_return_value)

          instance = klass.new
          expect(instance.existing_method).to eq :stubbed_return_value

          verify_all

          expect(instance.existing_method).to eq :existing_method_return_value
        end

       it "does not restore a stubbed method not originally implemented in the class" do
          allow_any_instance_of(::AnyInstanceSpec::ChildClass).to receive(:foo).and_return :result
          expect(::AnyInstanceSpec::ChildClass.new.foo).to eq :result

          reset_all
          expect(::AnyInstanceSpec::ChildClass.new.foo).to eq 'bar'
        end

        it "restores the original behaviour, even if the expectation fails" do
          expect_any_instance_of(klass).to receive(:existing_method).with(1).and_return(:stubbed_return_value)

          instance = klass.new
          begin
            instance.existing_method
            verify_all
          rescue RSpec::Mocks::MockExpectationError
          end

          reset_all

          expect(instance.existing_method).to eq :existing_method_return_value
        end
      end
    end
  end
end
