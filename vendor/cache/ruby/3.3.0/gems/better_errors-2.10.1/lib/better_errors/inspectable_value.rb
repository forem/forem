require "cgi"
require "objspace" rescue nil

module BetterErrors
  class ValueLargerThanConfiguredMaximum < StandardError; end

  class InspectableValue
    def initialize(value)
      @original_value = value
    end

    def to_html
      raise ValueLargerThanConfiguredMaximum unless value_small_enough_to_inspect?
      value_as_html
    end

    private

    attr_reader :original_value

    def value_as_html
      @value_as_html ||= CGI.escapeHTML(value)
    end

    def value
      @value ||= begin
        if original_value.respond_to? :inspect
          original_value.inspect
        else
          original_value
        end
      end
    end

    def value_small_enough_to_inspect?
      return true if BetterErrors.maximum_variable_inspect_size.nil?

      if defined?(ObjectSpace) && defined?(ObjectSpace.memsize_of) && ObjectSpace.memsize_of(value)
        ObjectSpace.memsize_of(value) <= BetterErrors.maximum_variable_inspect_size
      else
        value_as_html.length <= BetterErrors.maximum_variable_inspect_size
      end
    end
  end
end
