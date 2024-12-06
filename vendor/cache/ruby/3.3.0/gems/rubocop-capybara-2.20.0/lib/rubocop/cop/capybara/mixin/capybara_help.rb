# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Help methods for capybara.
      # @api private
      module CapybaraHelp
        COMMON_OPTIONS = %w[
          id class style
        ].freeze
        SPECIFIC_OPTIONS = {
          'button' => (
            COMMON_OPTIONS + %w[disabled name value title type]
          ).freeze,
          'link' => (
            COMMON_OPTIONS + %w[href alt title download]
          ).freeze,
          'table' => (
            COMMON_OPTIONS + %w[cols rows]
          ).freeze,
          'select' => (
            COMMON_OPTIONS + %w[
              disabled name placeholder
              selected multiple
            ]
          ).freeze,
          'field' => (
            COMMON_OPTIONS + %w[
              checked disabled name placeholder
              readonly type multiple
            ]
          ).freeze
        }.freeze
        SPECIFIC_PSEUDO_CLASSES = %w[
          not() disabled enabled checked unchecked
        ].freeze

        module_function

        # @param node [RuboCop::AST::SendNode]
        # @param locator [String]
        # @param element [String]
        # @return [Boolean]
        def replaceable_option?(node, locator, element)
          attrs = CssSelector.attributes(locator).keys
          return false unless replaceable_element?(node, element, attrs)

          attrs.all? do |attr|
            SPECIFIC_OPTIONS.fetch(element, []).include?(attr)
          end
        end

        # @param selector [String]
        # @return [Boolean]
        # @example
        #   common_attributes?('a[focused]') # => true
        #   common_attributes?('button[focused][visible]') # => true
        #   common_attributes?('table[id=some-id]') # => true
        #   common_attributes?('h1[invalid]') # => false
        def common_attributes?(selector)
          CssSelector.attributes(selector).keys.difference(COMMON_OPTIONS).none?
        end

        # @param attrs [Array<String>]
        # @return [Boolean]
        # @example
        #   replaceable_attributes?('table[id=some-id]') # => true
        #   replaceable_attributes?('a[focused]') # => false
        def replaceable_attributes?(attrs)
          attrs.values.none?(&:nil?)
        end

        # @param locator [String]
        # @return [Boolean]
        def replaceable_pseudo_classes?(locator)
          CssSelector.pseudo_classes(locator).all? do |pseudo_class|
            replaceable_pseudo_class?(pseudo_class, locator)
          end
        end

        # @param pseudo_class [String]
        # @param locator [String]
        # @return [Boolean]
        def replaceable_pseudo_class?(pseudo_class, locator)
          return false unless SPECIFIC_PSEUDO_CLASSES.include?(pseudo_class)

          case pseudo_class
          when 'not()' then replaceable_pseudo_class_not?(locator)
          else true
          end
        end

        # @param locator [String]
        # @return [Boolean]
        def replaceable_pseudo_class_not?(locator)
          locator.scan(/not\(.*?\)/).all? do |negation|
            CssSelector.attributes(negation).values.all? do |v|
              v.is_a?(TrueClass) || v.is_a?(FalseClass)
            end
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @param element [String]
        # @param attrs [Array<String>]
        # @return [Boolean]
        def replaceable_element?(node, element, attrs)
          case element
          when 'link' then replaceable_to_link?(node, attrs)
          else true
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @param attrs [Array<String>]
        # @return [Boolean]
        def replaceable_to_link?(node, attrs)
          include_option?(node, :href) || attrs.include?('href')
        end

        # @param node [RuboCop::AST::SendNode]
        # @param option [Symbol]
        # @return [Boolean]
        def include_option?(node, option)
          node.each_descendant(:sym).find { |opt| opt.value == option }
        end
      end
    end
  end
end
