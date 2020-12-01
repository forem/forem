require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'Constructing a verifying double' do
      include_context 'with isolated configuration'

      class ClassThatDynamicallyDefinesMethods
        def self.define_attribute_methods!
          define_method(:some_method_defined_dynamically) { true }
        end
      end

      module CustomModule
      end

      describe 'instance doubles' do
        it 'cannot be constructed with a non-module object' do
          expect {
            instance_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end

        it 'can be constructed with a struct' do
          o = instance_double(Struct.new(:defined_method), :defined_method => 1)
          expect(o.defined_method).to eq(1)
        end

        it 'allows named constants to be looked up and declared to verifying double callbacks' do
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.verify_doubled_constant_names = true
              config.when_declaring_verifying_double(&probe)
            end

            instance_double("RSpec::Mocks::ClassThatDynamicallyDefinesMethods")
          }.to yield_with_args(have_attributes :target => ClassThatDynamicallyDefinesMethods)
        end

        it 'allows anonymous constants to be looked up and declared to verifying double callbacks' do
          anonymous_module = Module.new
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.verify_doubled_constant_names = true
              config.when_declaring_verifying_double(&probe)
            end

            instance_double(anonymous_module)
          }.to yield_with_args(have_attributes :target => anonymous_module)
        end

        it 'allows classes to be customised' do
          test_class = Class.new(ClassThatDynamicallyDefinesMethods)

          RSpec.configuration.mock_with(:rspec) do |config|
            config.when_declaring_verifying_double do |reference|
              reference.target.define_attribute_methods!
            end
          end

          instance_double(test_class, :some_method_defined_dynamically => true)
        end

        describe 'any_instance' do
          let(:test_class) { Class.new(ClassThatDynamicallyDefinesMethods) }
          let(:not_implemented_error) { "#{test_class} does not implement #some_invalid_method" }

          before(:each) do
            RSpec.configuration.mock_with(:rspec) do |config|
              config.verify_partial_doubles = true
              config.when_declaring_verifying_double do |reference|
                reference.target.define_attribute_methods! if reference.target == test_class
              end
            end
          end

          it 'calls the callback for expect_any_instance_of' do
            expect_any_instance_of(test_class).to receive(:some_method_defined_dynamically)
            expect {
              expect_any_instance_of(test_class).to receive(:some_invalid_method)
            }.to raise_error(RSpec::Mocks::MockExpectationError, not_implemented_error)
            expect(test_class.new.some_method_defined_dynamically).to eq(nil)
          end

          it 'calls the callback for allow_any_instance_of' do
            allow_any_instance_of(test_class).to receive(:some_method_defined_dynamically)
            expect {
              allow_any_instance_of(test_class).to receive(:some_invalid_method)
            }.to raise_error(RSpec::Mocks::MockExpectationError, not_implemented_error)
            expect(test_class.new.some_method_defined_dynamically).to eq(nil)
          end

          it 'should not call the callback if verify_partial_doubles is off' do
            RSpec.configuration.mock_with(:rspec) do |config|
              config.verify_partial_doubles = false
            end

            expect(test_class.method_defined?(:some_method_defined_dynamically)).to be_falsey
          end
        end
      end

      describe 'class doubles' do
        it 'cannot be constructed with a non-module object' do
          expect {
            class_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end

        it 'declares named modules to verifying double callbacks' do
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.when_declaring_verifying_double(&probe)
            end
            class_double CustomModule
          }.to yield_with_args(have_attributes :target => CustomModule)
        end

        it 'declares anonymous modules to verifying double callbacks' do
          anonymous_module = Module.new
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.when_declaring_verifying_double(&probe)
            end
            class_double anonymous_module
          }.to yield_with_args(have_attributes :target => anonymous_module)
        end
      end

      describe 'object doubles' do
        it 'declares the class to verifying double callbacks' do
          object = Object.new

          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.when_declaring_verifying_double(&probe)
            end
            object_double object
          }.to yield_with_args(have_attributes :target => object)
        end
      end

      describe 'when verify_doubled_constant_names config option is set' do

        before do
          RSpec::Mocks.configuration.verify_doubled_constant_names = true
        end

        it 'prevents creation of instance doubles for unloaded constants' do
          expect {
            instance_double('LoadedClas')
          }.to raise_error(VerifyingDoubleNotDefinedError)
        end

        it 'prevents creation of class doubles for unloaded constants' do
          expect {
            class_double('LoadedClas')
          }.to raise_error(VerifyingDoubleNotDefinedError)
        end
      end

      it 'can only be named with a string or a module' do
        expect { instance_double(1) }.to raise_error(ArgumentError)
        expect { instance_double(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
