# frozen_string_literal: true

require 'xpath'

module Capybara
  class Selector
    # @api private
    class CSSBuilder
      def initialize(expression)
        @expression = expression || ''
      end

      attr_reader :expression

      def add_attribute_conditions(**attributes)
        @expression = attributes.inject(expression) do |css, (name, value)|
          conditions = if name == :class
            class_conditions(value)
          elsif value.is_a? Regexp
            regexp_conditions(name, value)
          else
            [attribute_conditions(name => value)]
          end

          ::Capybara::Selector::CSS.split(css).map do |sel|
            next sel if conditions.empty?

            conditions.map { |cond| sel + cond }.join(', ')
          end.join(', ')
        end
      end

    private

      def regexp_conditions(name, value)
        Selector::RegexpDisassembler.new(value).alternated_substrings.map do |strs|
          strs.map do |str|
            "[#{name}*='#{str}'#{' i' if value.casefold?}]"
          end.join
        end
      end

      def attribute_conditions(attributes)
        attributes.map do |attribute, value|
          case value
          when XPath::Expression
            raise ArgumentError, "XPath expressions are not supported for the :#{attribute} filter with CSS based selectors"
          when Regexp
            Selector::RegexpDisassembler.new(value).substrings.map do |str|
              "[#{attribute}*='#{str}'#{' i' if value.casefold?}]"
            end.join
          when true
            "[#{attribute}]"
          when false
            ':not([attribute])'
          else
            if attribute == :id
              "##{::Capybara::Selector::CSS.escape(value)}"
            else
              "[#{attribute}='#{value}']"
            end
          end
        end.join
      end

      def class_conditions(classes)
        case classes
        when XPath::Expression
          raise ArgumentError, 'XPath expressions are not supported for the :class filter with CSS based selectors'
        when Regexp
          Selector::RegexpDisassembler.new(classes).alternated_substrings.map do |strs|
            strs.map do |str|
              "[class*='#{str}'#{' i' if classes.casefold?}]"
            end.join
          end
        else
          cls = Array(classes).reject { |c| c.is_a? Regexp }.group_by { |cl| cl.match?(/^!(?!!!)/) }
          [(cls[false].to_a.map { |cl| ".#{Capybara::Selector::CSS.escape(cl.sub(/^!!/, ''))}" } +
          cls[true].to_a.map { |cl| ":not(.#{Capybara::Selector::CSS.escape(cl.slice(1..))})" }).join]
        end
      end
    end
  end
end
