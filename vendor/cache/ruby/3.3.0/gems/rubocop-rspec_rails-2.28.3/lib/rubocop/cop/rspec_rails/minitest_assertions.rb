# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Check if using Minitest-like matchers.
      #
      # Check the use of minitest-like matchers
      # starting with `assert_` or `refute_`.
      #
      # @example
      #   # bad
      #   assert_equal(a, b)
      #   assert_equal a, b, "must be equal"
      #   assert_not_includes a, b
      #   refute_equal(a, b)
      #   assert_nil a
      #   refute_empty(b)
      #   assert_true(a)
      #   assert_false(a)
      #
      #   # good
      #   expect(b).to eq(a)
      #   expect(b).to(eq(a), "must be equal")
      #   expect(a).not_to include(b)
      #   expect(b).not_to eq(a)
      #   expect(a).to eq(nil)
      #   expect(a).not_to be_empty
      #   expect(a).to be(true)
      #   expect(a).to be(false)
      #
      class MinitestAssertions < ::RuboCop::Cop::Base
        extend AutoCorrector

        # :nodoc:
        class BasicAssertion
          extend NodePattern::Macros

          attr_reader :expected, :actual, :failure_message

          def self.minitest_assertion
            raise NotImplementedError
          end

          def initialize(expected, actual, failure_message)
            @expected = expected&.source
            @actual = actual.source
            @failure_message = failure_message&.source
          end

          def replaced(node)
            runner = negated?(node) ? 'not_to' : 'to'
            if failure_message.nil?
              "expect(#{actual}).#{runner} #{assertion}"
            else
              "expect(#{actual}).#{runner}(#{assertion}, #{failure_message})"
            end
          end

          def negated?(node)
            node.method_name.start_with?('assert_not_', 'refute_')
          end

          def assertion
            raise NotImplementedError
          end
        end

        # :nodoc:
        class EqualAssertion < BasicAssertion
          MATCHERS = %i[
            assert_equal
            assert_not_equal
            refute_equal
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_equal :assert_not_equal :refute_equal} $_ $_ $_?)
          PATTERN

          def self.match(expected, actual, failure_message)
            new(expected, actual, failure_message.first)
          end

          def assertion
            "eq(#{expected})"
          end
        end

        # :nodoc:
        class KindOfAssertion < BasicAssertion
          MATCHERS = %i[
            assert_kind_of
            assert_not_kind_of
            refute_kind_of
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_kind_of :assert_not_kind_of :refute_kind_of} $_ $_ $_?)
          PATTERN

          def self.match(expected, actual, failure_message)
            new(expected, actual, failure_message.first)
          end

          def assertion
            "be_a_kind_of(#{expected})"
          end
        end

        # :nodoc:
        class InstanceOfAssertion < BasicAssertion
          MATCHERS = %i[
            assert_instance_of
            assert_not_instance_of
            refute_instance_of
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_instance_of :assert_not_instance_of :refute_instance_of} $_ $_ $_?)
          PATTERN

          def self.match(expected, actual, failure_message)
            new(expected, actual, failure_message.first)
          end

          def assertion
            "be_an_instance_of(#{expected})"
          end
        end

        # :nodoc:
        class IncludesAssertion < BasicAssertion
          MATCHERS = %i[
            assert_includes
            assert_not_includes
            refute_includes
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_includes :assert_not_includes :refute_includes} $_ $_ $_?)
          PATTERN

          def self.match(collection, expected, failure_message)
            new(expected, collection, failure_message.first)
          end

          def assertion
            "include(#{expected})"
          end
        end

        # :nodoc:
        class InDeltaAssertion < BasicAssertion
          MATCHERS = %i[
            assert_in_delta
            assert_not_in_delta
            refute_in_delta
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_in_delta :assert_not_in_delta :refute_in_delta} $_ $_ $_? $_?)
          PATTERN

          def self.match(expected, actual, delta, failure_message)
            new(expected, actual, delta.first, failure_message.first)
          end

          def initialize(expected, actual, delta, fail_message)
            super(expected, actual, fail_message)

            @delta = delta&.source || '0.001'
          end

          def assertion
            "be_within(#{@delta}).of(#{expected})"
          end
        end

        # :nodoc:
        class PredicateAssertion < BasicAssertion
          MATCHERS = %i[
            assert_predicate
            assert_not_predicate
            refute_predicate
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_predicate :assert_not_predicate :refute_predicate} $_ ${sym} $_?)
          PATTERN

          def self.match(subject, predicate, failure_message)
            return nil unless predicate.value.end_with?('?')

            new(predicate, subject, failure_message.first)
          end

          def assertion
            "be_#{expected.delete_prefix(':').delete_suffix('?')}"
          end
        end

        # :nodoc:
        class MatchAssertion < BasicAssertion
          MATCHERS = %i[
            assert_match
            refute_match
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_match :refute_match} $_ $_ $_?)
          PATTERN

          def self.match(matcher, actual, failure_message)
            new(matcher, actual, failure_message.first)
          end

          def assertion
            "match(#{expected})"
          end
        end

        # :nodoc:
        class NilAssertion < BasicAssertion
          MATCHERS = %i[
            assert_nil
            assert_not_nil
            refute_nil
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_nil :assert_not_nil :refute_nil} $_ $_?)
          PATTERN

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'eq(nil)'
          end
        end

        # :nodoc:
        class EmptyAssertion < BasicAssertion
          MATCHERS = %i[
            assert_empty
            assert_not_empty
            refute_empty
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_empty :assert_not_empty :refute_empty} $_ $_?)
          PATTERN

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'be_empty'
          end
        end

        # :nodoc:
        class TrueAssertion < BasicAssertion
          MATCHERS = %i[
            assert_true
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_true} $_ $_?)
          PATTERN

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'be(true)'
          end
        end

        # :nodoc:
        class FalseAssertion < BasicAssertion
          MATCHERS = %i[
            assert_false
          ].freeze

          # @!method self.minitest_assertion(node)
          def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
            (send nil? {:assert_false} $_ $_?)
          PATTERN

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'be(false)'
          end
        end

        MSG = 'Use `%<prefer>s`.'

        # TODO: replace with `BasicAssertion.subclasses` in Ruby 3.1+
        ASSERTION_MATCHERS = constants(false).filter_map do |c|
          const = const_get(c)

          const if const.is_a?(Class) && const.superclass == BasicAssertion
        end

        RESTRICT_ON_SEND = ASSERTION_MATCHERS.flat_map { |m| m::MATCHERS }

        def on_send(node)
          ASSERTION_MATCHERS.each do |m|
            m.minitest_assertion(node) do |*args|
              assertion = m.match(*args)

              next if assertion.nil?

              on_assertion(node, assertion)
            end
          end
        end

        def on_assertion(node, assertion)
          preferred = assertion.replaced(node)
          add_offense(node, message: message(preferred)) do |corrector|
            corrector.replace(node, preferred)
          end
        end

        def message(preferred)
          format(MSG, prefer: preferred)
        end
      end
    end
  end
end
