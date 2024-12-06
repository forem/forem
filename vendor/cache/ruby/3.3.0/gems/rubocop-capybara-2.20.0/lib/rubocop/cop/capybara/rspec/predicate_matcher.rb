# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      module RSpec
        # A helper for `inflected` style
        module InflectedHelper
          extend NodePattern::Macros

          EXPLICIT_MATCHER = %w[css selector style xpath].map do |suffix|
            "matches_#{suffix}?".to_sym
          end.freeze
          MSG_INFLECTED = 'Prefer using `%<matcher_name>s` matcher over ' \
                          '`%<predicate_name>s`.'

          private

          def check_inflected(node)
            predicate_in_actual?(node) do |predicate, to, matcher|
              msg = message_inflected(predicate)
              add_offense(node, message: msg) do |corrector|
                remove_predicate(corrector, predicate)
                corrector.replace(node.loc.selector,
                                  true?(to, matcher) ? 'to' : 'not_to')
                rewrite_matcher(corrector, predicate, matcher)
              end
            end
          end

          # @!method predicate_in_actual?(node)
          def_node_matcher :predicate_in_actual?, <<~PATTERN
            (send
              (send nil? :expect
                {
                  (block $(send !nil? #predicate? ...) ...)
                  $(send !nil? #predicate? ...)
                }
              )
              ${:to :to_not :not_to}
              $#boolean_matcher?
            )
          PATTERN

          # @!method be_bool?(node)
          def_node_matcher :be_bool?, <<~PATTERN
            (send nil? {:be :eq :eql :equal} {true false})
          PATTERN

          # @!method be_boolthy?(node)
          def_node_matcher :be_boolthy?, <<~PATTERN
            (send nil? {:be_truthy :be_falsey :be_falsy :a_truthy_value :a_falsey_value :a_falsy_value})
          PATTERN

          def boolean_matcher?(node)
            if cop_config['Strict']
              be_boolthy?(node)
            else
              be_bool?(node) || be_boolthy?(node)
            end
          end

          def predicate?(sym)
            EXPLICIT_MATCHER.include?(sym)
          end

          def message_inflected(predicate)
            format(MSG_INFLECTED,
                   predicate_name: predicate.method_name,
                   matcher_name: to_predicate_matcher(predicate.method_name))
          end

          def to_predicate_matcher(name)
            name.to_s.sub('matches_', 'match_')[0..-2]
          end

          def remove_predicate(corrector, predicate)
            range = predicate.loc.dot.with(
              end_pos: predicate.source_range.end_pos
            )

            corrector.remove(range)
          end

          def rewrite_matcher(corrector, predicate, matcher)
            args = args_loc(predicate).source

            corrector.replace(
              matcher,
              to_predicate_matcher(predicate.method_name) + args
            )
          end

          def true?(to_symbol, matcher)
            result = case matcher.method_name
                     when :be, :eq
                       matcher.first_argument.true_type?
                     when :be_truthy, :a_truthy_value
                       true
                     when :be_falsey, :be_falsy, :a_falsey_value, :a_falsy_value
                       false
                     end
            to_symbol == :to ? result : !result
          end
        end

        # A helper for `explicit` style
        module ExplicitHelper
          extend NodePattern::Macros

          MSG_EXPLICIT = 'Prefer using `%<predicate_name>s` over ' \
                         '`%<matcher_name>s` matcher.'
          BUILT_IN_MATCHERS = %w[
            be_truthy be_falsey be_falsy
            have_attributes have_received
            be_between be_within
          ].freeze
          INFLECTED_MATCHER = %w[css selector style xpath].each.map do |suffix|
            "match_#{suffix}"
          end.freeze

          private

          def allowed_explicit_matchers
            cop_config.fetch('AllowedExplicitMatchers', []) + BUILT_IN_MATCHERS
          end

          def check_explicit(node) # rubocop:disable Metrics/MethodLength
            predicate_matcher?(node) do |actual, matcher|
              add_offense(node,
                          message: message_explicit(matcher)) do |corrector|
                corrector_explicit(corrector, node, actual, matcher)
              end
            end
          end

          # @!method predicate_matcher?(node)
          def_node_matcher :predicate_matcher?, <<~PATTERN
            (send
              (send nil? :expect $!nil?)
              {:to :to_not :not_to}
              {
                $(send nil? #predicate_matcher_name? ...)
                (block $(send nil? #predicate_matcher_name? ...) ...)
              }
            )
          PATTERN

          def predicate_matcher_name?(name)
            name = name.to_s
            return false if allowed_explicit_matchers.include?(name)

            INFLECTED_MATCHER.include?(name)
          end

          def message_explicit(matcher)
            format(MSG_EXPLICIT,
                   predicate_name: to_predicate_method(matcher.method_name),
                   matcher_name: matcher.method_name)
          end

          def corrector_explicit(corrector, to_node, actual, matcher)
            replacement_matcher = replacement_matcher(to_node)
            corrector.replace(matcher, replacement_matcher)
            move_predicate(corrector, actual, matcher)
            corrector.replace(to_node.loc.selector, 'to')
          end

          def move_predicate(corrector, actual, matcher)
            predicate = to_predicate_method(matcher.method_name)
            args = args_loc(matcher).source
            corrector.insert_after(actual,
                                   ".#{predicate}" + args)
          end

          def to_predicate_method(matcher)
            "#{matcher.to_s.sub('match_', 'matches_')}?"
          end

          def replacement_matcher(node)
            case [cop_config['Strict'], node.method?(:to)]
            when [true, true]
              'be(true)'
            when [true, false]
              'be(false)'
            when [false, true]
              'be_truthy'
            when [false, false]
              'be_falsey'
            end
          end
        end

        # Prefer using predicate matcher over using predicate method directly.
        #
        # Capybara defines magic matchers for predicate methods.
        # This cop recommends to use the predicate matcher instead of using
        # predicate method directly.
        #
        # @example Strict: true, EnforcedStyle: inflected (default)
        #   # bad
        #   expect(foo.matches_css?(bar: 'baz')).to be_truthy
        #   expect(foo.matches_selector?(bar: 'baz')).to be_truthy
        #   expect(foo.matches_style?(bar: 'baz')).to be_truthy
        #   expect(foo.matches_xpath?(bar: 'baz')).to be_truthy
        #
        #   # good
        #   expect(foo).to match_css(bar: 'baz')
        #   expect(foo).to match_selector(bar: 'baz')
        #   expect(foo).to match_style(bar: 'baz')
        #   expect(foo).to match_xpath(bar: 'baz')
        #
        #   # also good - It checks "true" strictly.
        #   expect(foo.matches_style?(bar: 'baz')).to be(true)
        #
        # @example Strict: false, EnforcedStyle: inflected
        #   # bad
        #   expect(foo.matches_style?(bar: 'baz')).to be_truthy
        #   expect(foo.matches_style?(bar: 'baz')).to be(true)
        #
        #   # good
        #   expect(foo).to match_style(bar: 'baz')
        #
        # @example Strict: true, EnforcedStyle: explicit
        #   # bad
        #   expect(foo).to match_style(bar: 'baz')
        #
        #   # good - the above code is rewritten to it by this cop
        #   expect(foo.matches_style?(bar: 'baz')).to be(true)
        #
        # @example Strict: false, EnforcedStyle: explicit
        #   # bad
        #   expect(foo).to match_style(bar: 'baz')
        #
        #   # good - the above code is rewritten to it by this cop
        #   expect(foo.matches_style?(bar: 'baz')).to be_truthy
        #
        class PredicateMatcher < ::RuboCop::Cop::Base
          extend AutoCorrector
          include ConfigurableEnforcedStyle
          include InflectedHelper
          include ExplicitHelper

          RESTRICT_ON_SEND = %i[to to_not not_to].freeze

          def on_send(node)
            if style == :inflected
              check_inflected(node)
            elsif style == :explicit
              check_explicit(node)
            end
          end

          private

          # returns args location with whitespace
          # @example
          #   foo 1, 2
          #      ^^^^^
          def args_loc(send_node)
            send_node.loc.selector.end.with(
              end_pos: send_node.source_range.end_pos
            )
          end
        end
      end
    end
  end
end
