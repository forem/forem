# frozen_string_literal: true

require 'capybara/selector/filter'

module Capybara
  class Selector
    class FilterSet
      attr_reader :node_filters, :expression_filters

      def initialize(name, &block)
        @name = name
        @node_filters = {}
        @expression_filters = {}
        @descriptions = Hash.new { |hsh, key| hsh[key] = [] }
        instance_eval(&block) if block
      end

      def node_filter(names, *types, **options, &block)
        Array(names).each do |name|
          add_filter(name, Filters::NodeFilter, *types, **options, &block)
        end
      end
      alias_method :filter, :node_filter

      def expression_filter(name, *types, **options, &block)
        add_filter(name, Filters::ExpressionFilter, *types, **options, &block)
      end

      def describe(what = nil, &block)
        case what
        when nil
          undeclared_descriptions.push block
        when :node_filters
          node_filter_descriptions.push block
        when :expression_filters
          expression_filter_descriptions.push block
        else
          raise ArgumentError, 'Unknown description type'
        end
      end

      def description(node_filters: true, expression_filters: true, **options)
        opts = options_with_defaults(options)
        description = +''
        description << undeclared_descriptions.map { |desc| desc.call(**opts).to_s }.join
        description << expression_filter_descriptions.map { |desc| desc.call(**opts).to_s }.join if expression_filters
        description << node_filter_descriptions.map { |desc| desc.call(**opts).to_s }.join if node_filters
        description
      end

      def descriptions
        Capybara::Helpers.warn 'DEPRECATED: FilterSet#descriptions is deprecated without replacement'
        [undeclared_descriptions, node_filter_descriptions, expression_filter_descriptions].flatten
      end

      def import(name, filters = nil)
        filter_selector = filters.nil? ? ->(*) { true } : ->(filter_name, _) { filters.include? filter_name }

        self.class[name].tap do |f_set|
          expression_filters.merge!(f_set.expression_filters.select(&filter_selector))
          node_filters.merge!(f_set.node_filters.select(&filter_selector))
          f_set.undeclared_descriptions.each { |desc| describe(&desc) }
          f_set.expression_filter_descriptions.each { |desc| describe(:expression_filters, &desc) }
          f_set.node_filter_descriptions.each { |desc| describe(:node_filters, &desc) }
        end
        self
      end

      class << self
        def all
          @filter_sets ||= {} # rubocop:disable Naming/MemoizedInstanceVariableName
        end

        def [](name)
          all.fetch(name.to_sym) { |set_name| raise ArgumentError, "Unknown filter set (:#{set_name})" }
        end

        def add(name, &block)
          all[name.to_sym] = FilterSet.new(name.to_sym, &block)
        end

        def remove(name)
          all.delete(name.to_sym)
        end
      end

    protected

      def undeclared_descriptions
        @descriptions[:undeclared]
      end

      def node_filter_descriptions
        @descriptions[:node_filters]
      end

      def expression_filter_descriptions
        @descriptions[:expression_filters]
      end

    private

      def options_with_defaults(options)
        expression_filters.chain(node_filters)
                          .select { |_n, filter| filter.default? }
                          .each_with_object(options.dup) do |(name, filter), opts|
          opts[name] = filter.default unless opts.key?(name)
        end
      end

      def add_filter(name, filter_class, *types, matcher: nil, **options, &block)
        types.each { |type| options[type] = true }
        if matcher && options[:default]
          raise 'ArgumentError', ':default option is not supported for filters with a :matcher option'
        end

        filter = filter_class.new(name, matcher, block, **options)
        (filter_class <= Filters::ExpressionFilter ? @expression_filters : @node_filters)[name] = filter
      end
    end
  end
end
