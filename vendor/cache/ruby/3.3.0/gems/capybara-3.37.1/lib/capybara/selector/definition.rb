# frozen_string_literal: true

require 'capybara/selector/filter_set'
require 'capybara/selector/css'
require 'capybara/selector/regexp_disassembler'
require 'capybara/selector/builders/xpath_builder'
require 'capybara/selector/builders/css_builder'

module Capybara
  class Selector
    class Definition
      attr_reader :name, :expressions

      extend Forwardable

      def initialize(name, locator_type: nil, raw_locator: false, supports_exact: nil, &block)
        @name = name
        @filter_set = Capybara::Selector::FilterSet.add(name)
        @match = nil
        @label = nil
        @failure_message = nil
        @expressions = {}
        @expression_filters = {}
        @locator_filter = nil
        @default_visibility = nil
        @locator_type = locator_type
        @raw_locator = raw_locator
        @supports_exact = supports_exact
        instance_eval(&block)
      end

      def custom_filters
        warn "Deprecated: Selector#custom_filters is not valid when same named expression and node filter exist - don't use"
        node_filters.merge(expression_filters).freeze
      end

      def node_filters
        @filter_set.node_filters
      end

      def expression_filters
        @filter_set.expression_filters
      end

      ##
      #
      # Define a selector by an xpath expression
      #
      # @overload xpath(*expression_filters, &block)
      #   @param [Array<Symbol>] expression_filters ([])  Names of filters that are implemented via this expression, if not specified the names of any keyword parameters in the block will be used
      #   @yield [locator, options]                       The block to use to generate the XPath expression
      #   @yieldparam [String] locator                    The locator string passed to the query
      #   @yieldparam [Hash] options                      The options hash passed to the query
      #   @yieldreturn [#to_xpath, #to_s]                 An object that can produce an xpath expression
      #
      # @overload xpath()
      # @return [#call]                             The block that will be called to generate the XPath expression
      #
      def xpath(*allowed_filters, &block)
        expression(:xpath, allowed_filters, &block)
      end

      ##
      #
      # Define a selector by a CSS selector
      #
      # @overload css(*expression_filters, &block)
      #   @param [Array<Symbol>] expression_filters ([])  Names of filters that can be implemented via this CSS selector
      #   @yield [locator, options]                   The block to use to generate the CSS selector
      #   @yieldparam [String] locator               The locator string passed to the query
      #   @yieldparam [Hash] options                 The options hash passed to the query
      #   @yieldreturn [#to_s]                        An object that can produce a CSS selector
      #
      # @overload css()
      # @return [#call]                             The block that will be called to generate the CSS selector
      #
      def css(*allowed_filters, &block)
        expression(:css, allowed_filters, &block)
      end

      ##
      #
      # Automatic selector detection
      #
      # @yield [locator]                   This block takes the passed in locator string and returns whether or not it matches the selector
      # @yieldparam [String], locator      The locator string used to determine if it matches the selector
      # @yieldreturn [Boolean]             Whether this selector matches the locator string
      # @return [#call]                    The block that will be used to detect selector match
      #
      def match(&block)
        @match = block if block
        @match
      end

      ##
      #
      # Set/get a descriptive label for the selector
      #
      # @overload label(label)
      #   @param [String] label            A descriptive label for this selector - used in error messages
      # @overload label()
      # @return [String]                 The currently set label
      #
      def label(label = nil)
        @label = label if label
        @label
      end

      ##
      #
      # Description of the selector
      #
      # @!method description(options)
      #   @param [Hash] options            The options of the query used to generate the description
      #   @return [String]                 Description of the selector when used with the options passed
      def_delegator :@filter_set, :description

      ##
      #
      #  Should this selector be used for the passed in locator
      #
      #  This is used by the automatic selector selection mechanism when no selector type is passed to a selector query
      #
      # @param [String] locator     The locator passed to the query
      # @return [Boolean]           Whether or not to use this selector
      #
      def match?(locator)
        @match&.call(locator)
      end

      ##
      #
      # Define a node filter for use with this selector
      #
      # @!method node_filter(name, *types, options={}, &block)
      #   @param [Symbol, Regexp] name            The filter name
      #   @param [Array<Symbol>] types    The types of the filter - currently valid types are [:boolean]
      #   @param [Hash] options ({})      Options of the filter
      #   @option options [Array<>] :valid_values Valid values for this filter
      #   @option options :default        The default value of the filter (if any)
      #   @option options :skip_if        Value of the filter that will cause it to be skipped
      #   @option options [Regexp] :matcher (nil) A Regexp used to check whether a specific option is handled by this filter.  If not provided the filter will be used for options matching the filter name.
      #
      # If a Symbol is passed for the name the block should accept | node, option_value |, while if a Regexp
      # is passed for the name the block should accept | node, option_name, option_value |. In either case
      # the block should return `true` if the node passes the filer or `false` if it doesn't

      ##
      #
      # Define an expression filter for use with this selector
      #
      # @!method expression_filter(name, *types, matcher: nil, **options, &block)
      #   @param [Symbol, Regexp] name            The filter name
      #   @param [Regexp] matcher (nil)   A Regexp used to check whether a specific option is handled by this filter
      #   @param [Array<Symbol>] types    The types of the filter - currently valid types are [:boolean]
      #   @param [Hash] options ({})      Options of the filter
      #   @option options [Array<>] :valid_values Valid values for this filter
      #   @option options :default        The default value of the filter (if any)
      #   @option options :skip_if        Value of the filter that will cause it to be skipped
      #   @option options [Regexp] :matcher (nil) A Regexp used to check whether a specific option is handled by this filter.  If not provided the filter will be used for options matching the filter name.
      #
      # If a Symbol is passed for the name the block should accept | current_expression, option_value |, while if a Regexp
      # is passed for the name the block should accept | current_expression, option_name, option_value |. In either case
      # the block should return the modified expression

      def_delegators :@filter_set, :node_filter, :expression_filter, :filter

      def locator_filter(*types, **options, &block)
        types.each { |type| options[type] = true }
        @locator_filter = Capybara::Selector::Filters::LocatorFilter.new(block, **options) if block
        @locator_filter
      end

      def filter_set(name, filters_to_use = nil)
        @filter_set.import(name, filters_to_use)
      end

      def_delegator :@filter_set, :describe

      def describe_expression_filters(&block)
        if block
          describe(:expression_filters, &block)
        else
          describe(:expression_filters) do |**options|
            describe_all_expression_filters(**options)
          end
        end
      end

      def describe_all_expression_filters(**opts)
        expression_filters.map do |ef_name, ef|
          if ef.matcher?
            handled_custom_options(ef, opts).map { |option, value| " with #{ef_name}[#{option} => #{value}]" }.join
          elsif opts.key?(ef_name)
            " with #{ef_name} #{opts[ef_name]}"
          end
        end.join
      end

      def describe_node_filters(&block)
        describe(:node_filters, &block)
      end

      ##
      #
      # Set the default visibility mode that shouble be used if no visibile option is passed when using the selector.
      # If not specified will default to the behavior indicated by Capybara.ignore_hidden_elements
      #
      # @param [Symbol] default_visibility  Only find elements with the specified visibility:
      #                                              * :all - finds visible and invisible elements.
      #                                              * :hidden - only finds invisible elements.
      #                                              * :visible - only finds visible elements.
      def visible(default_visibility = nil, &block)
        @default_visibility = block || default_visibility
      end

      def default_visibility(fallback = Capybara.ignore_hidden_elements, options = {})
        vis = if @default_visibility.respond_to?(:call)
          @default_visibility.call(options)
        else
          @default_visibility
        end
        vis.nil? ? fallback : vis
      end

      # @api private
      def raw_locator?
        !!@raw_locator
      end

      # @api private
      def supports_exact?
        @supports_exact
      end

      def default_format
        return nil if @expressions.keys.empty?

        if @expressions.size == 1
          @expressions.keys.first
        else
          :xpath
        end
      end

      # @api private
      def locator_types
        return nil unless @locator_type

        Array(@locator_type)
      end

    private

      def handled_custom_options(filter, options)
        options.select do |option, _|
          filter.handles_option?(option) && !::Capybara::Queries::SelectorQuery::VALID_KEYS.include?(option)
        end
      end

      def parameter_names(block)
        key_types = %i[key keyreq]
        # user filter_map when we drop dupport for 2.6
        # block.parameters.select { |(type, _name)| key_types.include? type }.map { |(_, name)| name }
        block.parameters.filter_map { |(type, name)| name if key_types.include? type }
      end

      def expression(type, allowed_filters, &block)
        if block
          @expressions[type] = block
          allowed_filters = parameter_names(block) if allowed_filters.empty?
          allowed_filters.flatten.each do |ef|
            expression_filters[ef] = Capybara::Selector::Filters::IdentityExpressionFilter.new(ef)
          end
        end
        @expressions[type]
      end
    end
  end
end
