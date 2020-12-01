require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec::Matchers.define :fail_expectations_as do |expected|
      description { "include a meaningful name in the exception" }

      def error_message_for(_)
        expect(actual).to have_received(:defined_instance_and_class_method)
      rescue MockExpectationError, Expectations::ExpectationNotMetError => e
        e.message
      else
        raise("should have failed but did not")
      end

      failure_message do |actual|
        "expected #{actual.inspect} to fail expectations as:\n" \
          "  #{expected.inspect}, but failed with:\n" \
          "  #{@error_message.inspect}"
      end

      match do |actual|
        @error_message = error_message_for(actual)
        @error_message.include?(expected)
      end
    end

    RSpec.describe 'Verified double naming' do
      shared_examples "a named verifying double" do |type_desc|
        context "when a name is given as a string" do
          subject { create_double("LoadedClass", "foo") }
          it { is_expected.to fail_expectations_as(%Q{#{type_desc}(LoadedClass) "foo"}) }
        end

        context "when a name is given as a symbol" do
          subject { create_double("LoadedClass", :foo) }
          it { is_expected.to fail_expectations_as(%Q{#{type_desc}(LoadedClass) :foo}) }
        end

        context "when no name is given" do
          subject { create_double("LoadedClass") }
          it { is_expected.to fail_expectations_as(%Q{#{type_desc}(LoadedClass) (anonymous)}) }
        end
      end

      describe "instance_double" do
        it_behaves_like "a named verifying double", "InstanceDouble" do
          alias :create_double :instance_double
        end
      end

      describe "instance_spy" do
        it_behaves_like "a named verifying double", "InstanceDouble" do
          alias :create_double :instance_spy
        end
      end

      describe "class_double" do
        it_behaves_like "a named verifying double", "ClassDouble" do
          alias :create_double :class_double
        end
      end

      describe "class_spy" do
        it_behaves_like "a named verifying double", "ClassDouble" do
          alias :create_double :class_spy
        end
      end

      describe "object_double" do
        it_behaves_like "a named verifying double", "ObjectDouble" do
          alias :create_double :object_double
        end
      end

      describe "object_spy" do
        it_behaves_like "a named verifying double", "ObjectDouble" do
          alias :create_double :object_spy
        end
      end
    end
  end
end
