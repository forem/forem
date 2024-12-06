# frozen_string_literal: true

require 'xpath'

module Capybara
  class Selector
    # @api private
    class XPathBuilder
      def initialize(expression)
        @expression = expression || ''
      end

      attr_reader :expression

      def add_attribute_conditions(**conditions)
        @expression = conditions.inject(expression) do |xp, (name, value)|
          conditions = name == :class ? class_conditions(value) : attribute_conditions(name => value)
          return xp if conditions.nil?

          if xp.is_a? XPath::Expression
            xp[conditions]
          else
            "(#{xp})[#{conditions}]"
          end
        end
      end

    private

      def attribute_conditions(attributes)
        attributes.map do |attribute, value|
          case value
          when XPath::Expression
            XPath.attr(attribute)[value]
          when Regexp
            XPath.attr(attribute)[regexp_to_xpath_conditions(value)]
          when true
            XPath.attr(attribute)
          when false, nil
            !XPath.attr(attribute)
          else
            XPath.attr(attribute) == value.to_s
          end
        end.reduce(:&)
      end

      def class_conditions(classes)
        case classes
        when XPath::Expression, Regexp
          attribute_conditions(class: classes)
        else
          Array(classes).reject { |c| c.is_a? Regexp }.map do |klass|
            if klass.match?(/^!(?!!!)/)
              !XPath.attr(:class).contains_word(klass.slice(1..))
            else
              XPath.attr(:class).contains_word(klass.sub(/^!!/, ''))
            end
          end.reduce(:&)
        end
      end

      def regexp_to_xpath_conditions(regexp)
        condition = XPath.current
        condition = condition.uppercase if regexp.casefold?
        Selector::RegexpDisassembler.new(regexp).alternated_substrings.map do |strs|
          strs.map { |str| condition.contains(str) }.reduce(:&)
        end.reduce(:|)
      end
    end
  end
end
