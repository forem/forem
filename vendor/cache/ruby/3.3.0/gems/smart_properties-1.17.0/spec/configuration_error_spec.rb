require 'spec_helper'

RSpec.describe SmartProperties, 'configuration error' do
  subject(:klass) { DummyClass.new }

  context "when defining a property with invalid configuration options" do
    it "should report all invalid options" do
      invalid_property_definition = lambda do
        klass.class_eval do
          property :title, invalid_option_1: 'boom', invalid_option_2: 'boom', invalid_option_3: 'boom'
        end
      end

      expect(&invalid_property_definition).to raise_error(SmartProperties::ConfigurationError, "SmartProperties do not support the following configuration options: invalid_option_1, invalid_option_2, invalid_option_3.")
    end

    it "should accept default values that can't be mutated" do
      valid_property_definition = lambda do
        klass.class_eval do
          property :proc, default: -> { }
          property :numeric_float, default: 1.23
          property :numeric_int, default: 456
          property :string, default: "abc"
          property :range, default: 123...456
          property :bool_true, default: true
          property :bool_false, default: false
          property :nil, default: nil
          property :symbol, default: :abc
          property :module, default: Integer
        end
      end

      expect(&valid_property_definition).not_to raise_error
    end

    it "should not accept default values that may be mutated" do
      invalid_property_definition = lambda do
        klass.class_eval do
          property :title, default: []
        end
      end

      expect(&invalid_property_definition).to(
        raise_error(SmartProperties::ConfigurationError,
          "Default attribute value [] cannot be specified as literal, "\
            "use the syntax `default: -> { ... }` instead.")
      )
    end
  end
end
