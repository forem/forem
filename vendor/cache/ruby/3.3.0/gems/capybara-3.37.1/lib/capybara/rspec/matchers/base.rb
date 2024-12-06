# frozen_string_literal: true

require 'capybara/rspec/matchers/compound'
require 'capybara/rspec/matchers/count_sugar'
require 'capybara/rspec/matchers/spatial_sugar'

module Capybara
  module RSpecMatchers
    module Matchers
      class Base
        include ::Capybara::RSpecMatchers::Matchers::Compound if defined?(::Capybara::RSpecMatchers::Matchers::Compound)

        attr_reader :failure_message, :failure_message_when_negated

        def initialize(*args, **kw_args, &filter_block)
          @args = args.dup
          @kw_args = kw_args || {}
          @filter_block = filter_block
        end

      private

        def session_query_args
          # if @args.last.is_a? Hash
          #   @args.last[:session_options] = session_options
          # else
          #   @args.push(session_options: session_options)
          # end
          @args
        end

        def session_query_options
          @kw_args[:session_options] = session_options
          @kw_args
        end

        def session_options
          @context_el ||= nil
          if @context_el.respond_to? :session_options
            @context_el.session_options
          elsif @context_el.respond_to? :current_scope
            @context_el.current_scope.session_options
          else
            Capybara.session_options
          end
        end
      end

      class WrappedElementMatcher < Base
        def matches?(actual)
          element_matches?(wrap(actual))
        rescue Capybara::ExpectationNotMet => e
          @failure_message = e.message
          false
        end

        def does_not_match?(actual)
          element_does_not_match?(wrap(actual))
        rescue Capybara::ExpectationNotMet => e
          @failure_message_when_negated = e.message
          false
        end

      private

        def wrap(actual)
          actual = actual.to_capybara_node if actual.respond_to?(:to_capybara_node)
          @context_el = if actual.respond_to?(:has_selector?)
            actual
          else
            Capybara.string(actual.to_s)
          end
        end
      end

      class CountableWrappedElementMatcher < WrappedElementMatcher
        include ::Capybara::RSpecMatchers::CountSugar
        include ::Capybara::RSpecMatchers::SpatialSugar
      end

      class NegatedMatcher
        include ::Capybara::RSpecMatchers::Matchers::Compound if defined?(::Capybara::RSpecMatchers::Matchers::Compound)

        def initialize(matcher)
          super()
          @matcher = matcher
        end

        def matches?(actual)
          @matcher.does_not_match?(actual)
        end

        def does_not_match?(actual)
          @matcher.matches?(actual)
        end

        def description
          "not #{@matcher.description}"
        end

        def failure_message
          @matcher.failure_message_when_negated
        end

        def failure_message_when_negated
          @matcher.failure_message
        end
      end
    end
  end
end
