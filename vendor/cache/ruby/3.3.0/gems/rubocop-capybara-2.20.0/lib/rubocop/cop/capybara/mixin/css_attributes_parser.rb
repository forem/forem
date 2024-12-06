# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Css selector parser.
      # @api private
      class CssAttributesParser
        def initialize(selector)
          @selector = selector
          @state = :initial
          @temp = ''
          @results = {}
          @bracket_count = 0
        end

        # @return [Array<String>]
        def parse # rubocop:disable Metrics/MethodLength
          @selector.chars do |char|
            if char == '['
              on_bracket_start
            elsif char == ']'
              on_bracket_end
            elsif @state == :inside_attr
              @temp += char
            end
          end
          @results
        end

        private

        def on_bracket_start
          @bracket_count += 1
          if @state == :initial
            @state = :inside_attr
          else
            @temp += '['
          end
        end

        def on_bracket_end
          @bracket_count -= 1
          if @bracket_count.zero?
            @state = :initial
            key, value = @temp.split('=')
            @results[key] = normalize_value(value)
            @temp.clear
          else
            @temp += ']'
          end
        end

        # @param value [String]
        # @return [Boolean, String]
        # @example
        #   normalize_value('true') # => true
        #   normalize_value('false') # => false
        #   normalize_value(nil) # => nil
        #   normalize_value("foo") # => "'foo'"
        def normalize_value(value)
          case value
          when 'true' then true
          when 'false' then false
          when nil then nil
          else "'#{value.gsub(/"|'/, '')}'"
          end
        end
      end
    end
  end
end
