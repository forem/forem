require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'An instance double with the doubled class loaded' do
      include_context "with isolated configuration"

      before do
        RSpec::Mocks.configuration.verify_doubled_constant_names = true
      end

      it 'only allows instance methods that exist to be stubbed' do
        o = instance_double('LoadedClass', :defined_instance_method => 1)
        expect(o.defined_instance_method).to eq(1)

        prevents(/does not implement the instance method/) { allow(o).to receive(:undefined_instance_method) }
        prevents(/does not implement the instance method/) { allow(o).to receive(:defined_class_method) }
      end

      it 'only allows instance methods that exist to be expected' do
        o = instance_double('LoadedClass')
        expect(o).to receive(:defined_instance_method)
        o.defined_instance_method

        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_class_method) }
        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_class_method) }
      end

      USE_CLASS_DOUBLE_MSG = "Perhaps you meant to use `class_double`"

      it "suggests using `class_double` when a class method is stubbed" do
        o = instance_double("LoadedClass")
        prevents(a_string_including(USE_CLASS_DOUBLE_MSG)) { allow(o).to receive(:defined_class_method) }
      end

      it "doesn't suggest `class_double` when a non-class method is stubbed" do
        o = instance_double("LoadedClass")
        prevents(a_string_excluding(USE_CLASS_DOUBLE_MSG)) { allow(o).to receive(:undefined_class_method) }
      end

      it 'allows `send` to be stubbed if it is defined on the class' do
        o = instance_double('LoadedClass')
        allow(o).to receive(:send).and_return("received")
        expect(o.send(:msg)).to eq("received")
      end

      it 'gives a descriptive error message for NoMethodError' do
        o = instance_double("LoadedClass")
        expect {
          o.defined_private_method
        }.to raise_error(NoMethodError,
                         a_string_including("InstanceDouble(LoadedClass)"))
      end

      it 'does not allow dynamic methods to be expected' do
        # This isn't possible at the moment since an instance of the class
        # would be required for the verification, and we only have the
        # class itself.
        #
        # This spec exists as "negative" documentation of the absence of a
        # feature, to highlight the asymmetry from class doubles (that do
        # support this behaviour).
        prevents {
          instance_double('LoadedClass', :dynamic_instance_method => 1)
        }
      end

      it 'checks the arity of stubbed methods' do
        o = instance_double('LoadedClass')
        prevents {
          expect(o).to receive(:defined_instance_method).with(:a)
        }

        reset o
      end

      it 'checks that stubbed methods are invoked with the correct arity' do
        o = instance_double('LoadedClass', :defined_instance_method => 25)
        expect {
          o.defined_instance_method(:a)
        }.to raise_error(ArgumentError, "Wrong number of arguments. Expected 0, got 1.")
      end

      if required_kw_args_supported?
        it 'allows keyword arguments' do
          o = instance_double('LoadedClass', :kw_args_method => true)
          expect(o.kw_args_method(1, :required_arg => 'something')).to eq(true)
        end

        context 'for a method that only accepts keyword args' do
          it 'allows hash matchers like `hash_including` to be used in place of the keywords arg hash' do
            o = instance_double('LoadedClass')
            expect(o).to receive(:kw_args_method).
              with(1, hash_including(:required_arg => 1))
            o.kw_args_method(1, :required_arg => 1)
          end

          it 'allows anything matcher to be used in place of the keywords arg hash' do
            o = instance_double('LoadedClass')
            expect(o).to receive(:kw_args_method).with(1, anything)
            o.kw_args_method(1, :required_arg => 1)
          end

          it 'still checks positional arguments when matchers used for keyword args' do
            o = instance_double('LoadedClass')
            prevents(/Expected 1, got 3/) {
              expect(o).to receive(:kw_args_method).
                with(1, 2, 3, hash_including(:required_arg => 1))
            }
            reset o
          end

          it 'does not allow matchers to be used in an actual method call' do
            o = instance_double('LoadedClass')
            matcher = hash_including(:required_arg => 1)
            allow(o).to receive(:kw_args_method).with(1, matcher)
            expect {
              o.kw_args_method(1, matcher)
            }.to raise_error(ArgumentError)
          end
        end

        context 'for a method that accepts a mix of optional keyword and positional args' do
          it 'allows hash matchers like `hash_including` to be used in place of the keywords arg hash' do
            o = instance_double('LoadedClass')
            expect(o).to receive(:mixed_args_method).with(1, 2, hash_including(:optional_arg_1 => 1))
            o.mixed_args_method(1, 2, :optional_arg_1 => 1)
          end
        end

        it 'checks that stubbed methods with required keyword args are ' \
           'invoked with the required arguments' do
          o = instance_double('LoadedClass', :kw_args_method => true)
          expect {
            o.kw_args_method(:optional_arg => 'something')
          }.to raise_error(ArgumentError)
        end
      end

      it 'validates `with` args against the method signature when stubbing a method' do
        dbl = instance_double(LoadedClass)
        prevents(/Wrong number of arguments. Expected 2, got 3./) {
          allow(dbl).to receive(:instance_method_with_two_args).with(3, :foo, :args)
        }
      end

      it 'allows class to be specified by constant' do
        o = instance_double(LoadedClass, :defined_instance_method => 1)
        expect(o.defined_instance_method).to eq(1)
      end

      context "when the class const has been previously stubbed" do
        before { class_double(LoadedClass).as_stubbed_const }

        it "uses the original class to verify against for `instance_double('LoadedClass')`" do
          o = instance_double("LoadedClass")
          allow(o).to receive(:defined_instance_method)
          prevents { allow(o).to receive(:undefined_method) }
        end

        it "uses the original class to verify against for `instance_double(LoadedClass)`" do
          o = instance_double(LoadedClass)
          allow(o).to receive(:defined_instance_method)
          prevents { allow(o).to receive(:undefined_method) }
        end
      end

      context "when given a class that has an overridden `#name` method" do
        it "properly verifies" do
          o = instance_double(LoadedClassWithOverriddenName)
          allow(o).to receive(:defined_instance_method)
          prevents { allow(o).to receive(:undefined_method) }
        end
      end

      context 'for null objects' do
        let(:obj) { instance_double('LoadedClass').as_null_object }

        it 'only allows defined methods' do
          expect(obj.defined_instance_method).to eq(obj)
          prevents { obj.undefined_method }
          prevents { obj.send(:undefined_method) }
          prevents { obj.__send__(:undefined_method) }
        end

        it 'verifies arguments' do
          expect {
            obj.defined_instance_method(:too, :many, :args)
          }.to raise_error(ArgumentError, "Wrong number of arguments. Expected 0, got 3.")
        end

        it "includes the double's name in a private method error" do
          expect {
            obj.rand
          }.to raise_error(NoMethodError, a_string_including("private", "InstanceDouble(LoadedClass)"))
        end

        it 'reports what public messages it responds to accurately' do
          expect(obj.respond_to?(:defined_instance_method)).to be true
          expect(obj.respond_to?(:defined_instance_method, true)).to be true
          expect(obj.respond_to?(:defined_instance_method, false)).to be true

          expect(obj.respond_to?(:undefined_method)).to be false
          expect(obj.respond_to?(:undefined_method, true)).to be false
          expect(obj.respond_to?(:undefined_method, false)).to be false
        end

        it 'reports that it responds to defined private methods when the appropriate arg is passed' do
          expect(obj.respond_to?(:defined_private_method)).to be false
          expect(obj.respond_to?(:defined_private_method, true)).to be true
          expect(obj.respond_to?(:defined_private_method, false)).to be false
        end

        if RUBY_VERSION.to_f < 2.0 # respond_to?(:protected_method) changed behavior in Ruby 2.0.
          it 'reports that it responds to protected methods' do
            expect(obj.respond_to?(:defined_protected_method)).to be true
            expect(obj.respond_to?(:defined_protected_method, true)).to be true
            expect(obj.respond_to?(:defined_protected_method, false)).to be true
          end
        else
          it 'reports that it responds to protected methods when the appropriate arg is passed' do
            expect(obj.respond_to?(:defined_protected_method)).to be false
            expect(obj.respond_to?(:defined_protected_method, true)).to be true
            expect(obj.respond_to?(:defined_protected_method, false)).to be false
          end
        end
      end
    end
  end
end
