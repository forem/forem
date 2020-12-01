require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe "Method visibility for verified doubles" do
      include_context "with isolated configuration"

      before do
        RSpec::Mocks.configuration.verify_doubled_constant_names = true
      end

      context "for an instance double (when the class is loaded)" do
        shared_examples "preserves method visibility" do |visibility|
          method_name = :"defined_#{visibility}_method"

          it "can allow a #{visibility} instance method" do
            o = instance_double('LoadedClass')
            allow(o).to receive(method_name).and_return(3)
            expect(o.send method_name).to eq(3)
          end

          it "can expect a #{visibility} instance method" do
            o = instance_double('LoadedClass')
            expect(o).to receive(method_name)
            o.send method_name
          end

          it "preserves #{visibility} visibility when allowing a #{visibility} method" do
            preserves_visibility(method_name, visibility) do
              instance_double('LoadedClass').tap do |o|
                allow(o).to receive(method_name)
              end
            end
          end

          it "preserves #{visibility} visibility when expecting a #{visibility} method" do
            preserves_visibility(method_name, visibility) do
              instance_double('LoadedClass').tap do |o|
                expect(o).to receive(method_name).at_least(:once)
                o.send(method_name) # to satisfy the expectation
              end
            end
          end

          it "preserves #{visibility} visibility on a null object" do
            preserves_visibility(method_name, visibility) do
              instance_double('LoadedClass').as_null_object
            end
          end
        end

        include_examples "preserves method visibility", :private
        include_examples "preserves method visibility", :protected
      end

      context "for a class double (when the class is loaded)" do
        shared_examples "preserves method visibility" do |visibility|
          method_name = :"defined_#{visibility}_class_method"

          it "can allow a #{visibility} instance method" do
            o = class_double('LoadedClass')
            allow(o).to receive(method_name).and_return(3)
            expect(o.send method_name).to eq(3)
          end

          it "can expect a #{visibility} instance method" do
            o = class_double('LoadedClass')
            expect(o).to receive(method_name)
            o.send method_name
          end

          it "preserves #{visibility} visibility when allowing a #{visibility} method" do
            preserves_visibility(method_name, visibility) do
              class_double('LoadedClass').tap do |o|
                allow(o).to receive(method_name)
              end
            end
          end

          it "preserves #{visibility} visibility when expecting a #{visibility} method" do
            preserves_visibility(method_name, visibility) do
              class_double('LoadedClass').tap do |o|
                expect(o).to receive(method_name).at_least(:once)
                o.send(method_name) # to satisfy the expectation
              end
            end
          end

          it "preserves #{visibility} visibility on a null object" do
            preserves_visibility(method_name, visibility) do
              class_double('LoadedClass').as_null_object
            end
          end
        end

        include_examples "preserves method visibility", :private
        include_examples "preserves method visibility", :protected
      end

      def preserves_visibility(method_name, visibility)
        double = yield

        expect {
          # send bypasses visbility, so we use eval instead.
          eval("double.#{method_name}")
        }.to raise_error(NoMethodError, a_message_indicating_visibility_violation(method_name, visibility))

        expect { double.send(method_name) }.not_to raise_error
        expect { double.__send__(method_name) }.not_to raise_error

        unless double.null_object?
          # Null object doubles use `method_missing` and so the singleton class
          # doesn't know what methods are defined.
          singleton_class = class << double; self; end
          expect(singleton_class.send("#{visibility}_method_defined?", method_name)).to be true
        end
      end

      RSpec::Matchers.define :a_message_indicating_visibility_violation do |method_name, visibility|
        match do |msg|
          # This should NOT Be just `msg.match(visibility)` because the method being called
          # has the visibility name in it. We want to ensure it's a message that ruby is
          # stating is of the given visibility.
          msg.match("#{visibility} ") && msg.match(method_name.to_s)
        end
      end
    end
  end
end
