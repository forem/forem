# frozen_string_literal: true

module Capybara
  class Selector < SimpleDelegator
    class << self
      def all
        @definitions ||= {} # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      def [](name)
        all.fetch(name.to_sym) { |sel_type| raise ArgumentError, "Unknown selector type (:#{sel_type})" }
      end

      def add(name, **options, &block)
        all[name.to_sym] = Definition.new(name.to_sym, **options, &block)
      end

      def update(name, &block)
        self[name].instance_eval(&block)
      end

      def remove(name)
        all.delete(name.to_sym)
      end

      def for(locator)
        all.values.find { |sel| sel.match?(locator) }
      end
    end

    attr_reader :errors

    def initialize(definition, config:, format:)
      definition = self.class[definition] unless definition.is_a? Definition
      super(definition)
      @definition = definition
      @config = config
      @format = format
      @errors = []
    end

    def format
      @format || @definition.default_format
    end
    alias_method :current_format, :format

    def enable_aria_label
      @config[:enable_aria_label]
    end

    def enable_aria_role
      @config[:enable_aria_role]
    end

    def test_id
      @config[:test_id]
    end

    def call(locator, **options)
      if format
        raise ArgumentError, "Selector #{@name} does not support #{format}" unless expressions.key?(format)

        instance_exec(locator, **options, &expressions[format])
      else
        warn 'Selector has no format'
      end
    ensure
      unless locator_valid?(locator)
        Capybara::Helpers.warn(
          "Locator #{locator.class}:#{locator.inspect} for selector #{name.inspect} must #{locator_description}. " \
          'This will raise an error in a future version of Capybara. ' \
          "Called from: #{Capybara::Helpers.filter_backtrace(caller)}"
        )
      end
    end

    def add_error(error_msg)
      errors << error_msg
    end

    def expression_for(name, locator, config: @config, format: current_format, **options)
      Selector.new(name, config: config, format: format).call(locator, **options)
    end

    # @api private
    def with_filter_errors(errors)
      old_errors = @errors
      @errors = errors
      yield
    ensure
      @errors = old_errors
    end

    # @api private
    def builder(expr = nil)
      case format
      when :css
        Capybara::Selector::CSSBuilder
      when :xpath
        Capybara::Selector::XPathBuilder
      else
        raise NotImplementedError, "No builder exists for selector of type #{default_format}"
      end.new(expr)
    end

  private

    def locator_description
      locator_types.group_by { |lt| lt.is_a? Symbol }.map do |symbol, types_or_methods|
        if symbol
          "respond to #{types_or_methods.join(' or ')}"
        else
          "be an instance of #{types_or_methods.join(' or ')}"
        end
      end.join(' or ')
    end

    def locator_valid?(locator)
      return true unless locator && locator_types

      locator_types&.any? do |type_or_method|
        type_or_method.is_a?(Symbol) ? locator.respond_to?(type_or_method) : type_or_method === locator # rubocop:disable Style/CaseEquality
      end
    end

    def locate_field(xpath, locator, **_options)
      return xpath if locator.nil?

      locate_xpath = xpath # Need to save original xpath for the label wrap
      locator = locator.to_s
      attr_matchers = [XPath.attr(:id) == locator,
                       XPath.attr(:name) == locator,
                       XPath.attr(:placeholder) == locator,
                       XPath.attr(:id) == XPath.anywhere(:label)[XPath.string.n.is(locator)].attr(:for)].reduce(:|)
      attr_matchers |= XPath.attr(:'aria-label').is(locator) if enable_aria_label
      attr_matchers |= XPath.attr(test_id) == locator if test_id

      locate_xpath = locate_xpath[attr_matchers]
      locate_xpath + locate_label(locator).descendant(xpath)
    end

    def locate_label(locator)
      XPath.descendant(:label)[XPath.string.n.is(locator)]
    end

    def find_by_attr(attribute, value)
      finder_name = "find_by_#{attribute}_attr"
      if respond_to?(finder_name, true)
        send(finder_name, value)
      else
        value ? XPath.attr(attribute) == value : nil
      end
    end

    def find_by_class_attr(classes)
      Array(classes).map { |klass| XPath.attr(:class).contains_word(klass) }.reduce(:&)
    end
  end
end
