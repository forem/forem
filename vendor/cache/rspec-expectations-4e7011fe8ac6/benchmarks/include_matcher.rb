require 'benchmark/ips'
require 'rspec/expectations'

include RSpec::Matchers

module RSpec
  module Matchers
    module BuiltIn
      class OldInclude < BaseMatcher
        def initialize(*expected)
          @expected = expected
        end

        def matches?(actual)
          @actual = actual
          perform_match(:all?, :all?)
        end

        def does_not_match?(actual)
          @actual = actual
          perform_match(:none?, :any?)
        end

        def description
          described_items = surface_descriptions_in(expected)
          item_list = EnglishPhrasing.list(described_items)
          improve_hash_formatting "include#{item_list}"
        end

        def failure_message
          improve_hash_formatting(super) + invalid_object_message
        end

        def failure_message_when_negated
          improve_hash_formatting(super) + invalid_object_message
        end

        def diffable?
          !diff_would_wrongly_highlight_matched_item?
        end

      private

        def invalid_object_message
          return '' if actual.respond_to?(:include?)
          ", but it does not respond to `include?`"
        end

        def perform_match(predicate, hash_subset_predicate)
          return false unless actual.respond_to?(:include?)

          expected.__send__(predicate) do |expected_item|
            if comparing_hash_to_a_subset?(expected_item)
              expected_item.__send__(hash_subset_predicate) do |(key, value)|
                actual_hash_includes?(key, value)
              end
            elsif comparing_hash_keys?(expected_item)
              actual_hash_has_key?(expected_item)
            else
              actual_collection_includes?(expected_item)
            end
          end
        end

        def comparing_hash_to_a_subset?(expected_item)
          actual.is_a?(Hash) && expected_item.is_a?(Hash)
        end

        def actual_hash_includes?(expected_key, expected_value)
          actual_value = actual.fetch(expected_key) { return false }
          values_match?(expected_value, actual_value)
        end

        def comparing_hash_keys?(expected_item)
          actual.is_a?(Hash) && !expected_item.is_a?(Hash)
        end

        def actual_hash_has_key?(expected_key)
          actual.key?(expected_key) ||
          actual.keys.any? { |key| values_match?(expected_key, key) }
        end

        def actual_collection_includes?(expected_item)
          return true if actual.include?(expected_item)

          return false unless actual.respond_to?(:any?)

          actual.any? { |value| values_match?(expected_item, value) }
        end

        def diff_would_wrongly_highlight_matched_item?
          return false unless actual.is_a?(String) && expected.is_a?(Array)

          lines = actual.split("\n")
          expected.any? do |str|
            actual.include?(str) && lines.none? { |line| line == str }
          end
        end
      end
    end

    def old_include(*expected)
      BuiltIn::OldInclude.new(*expected)
    end
  end
end

array_sizes = [10, 50, 100, 500]

# *maniacal laugh*
class << self; alias_method :inc, :include; remove_method :include; end

Benchmark.ips do |x|
  x.report("Old `to include` successes") do
    array_sizes.each do |n|
      expect([*1..n]).to old_include(*n/2..n)
    end
  end

  x.report("New `to include` successes") do
    array_sizes.each do |n|
      expect([*1..n]).to include(*n/2..n)
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.report("Old `to include` failures") do
    array_sizes.each do |n|
      begin
        expect([*1..n]).to old_include(*n+1..n*1.5)
      rescue RSpec::Expectations::ExpectationNotMetError
      end
    end
  end

  x.report("New `to include` failures") do
    array_sizes.each do |n|
      begin
        expect([*1..n]).to include(*n+1..n*1.5)
      rescue RSpec::Expectations::ExpectationNotMetError
      end
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.report("Old `to not include` successes") do
    array_sizes.each do |n|
      expect([*1..n]).to_not old_include(*n+1..n*1.5)
    end
  end

  x.report("New `to not include` successes") do
    array_sizes.each do |n|
      expect([*1..n]).to_not include(*n+1..n*1.5)
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.report("Old `to not include` failures") do
    array_sizes.each do |n|
      begin
        expect([*1..n]).to_not old_include(*n/2..n)
      rescue RSpec::Expectations::ExpectationNotMetError
      end
    end
  end

  x.report("New `to not include` failures") do
    array_sizes.each do |n|
      begin
        expect([*1..n]).to_not include(*n/2..n)
      rescue RSpec::Expectations::ExpectationNotMetError
      end
    end
  end

  x.compare!
end

__END__

Calculating -------------------------------------
Old `to include` successes
                        30.000  i/100ms
New `to include` successes
                        28.000  i/100ms
-------------------------------------------------
Old `to include` successes
                        307.740  (± 4.2%) i/s -      1.560k
New `to include` successes
                        299.321  (± 2.7%) i/s -      1.512k

Comparison:
Old `to include` successes:      307.7 i/s
New `to include` successes:      299.3 i/s - 1.03x slower

Calculating -------------------------------------
Old `to include` failures
                         2.000  i/100ms
New `to include` failures
                         1.000  i/100ms
-------------------------------------------------
Old `to include` failures
                         20.611  (± 4.9%) i/s -    104.000
New `to include` failures
                          2.990  (± 0.0%) i/s -     15.000

Comparison:
Old `to include` failures:       20.6 i/s
New `to include` failures:        3.0 i/s - 6.89x slower

Calculating -------------------------------------
Old `to not include` successes
                         1.000  i/100ms
New `to not include` successes
                         1.000  i/100ms
-------------------------------------------------
Old `to not include` successes
                          3.505  (± 0.0%) i/s -     18.000
New `to not include` successes
                          3.475  (± 0.0%) i/s -     18.000

Comparison:
Old `to not include` successes:        3.5 i/s
New `to not include` successes:        3.5 i/s - 1.01x slower

Calculating -------------------------------------
Old `to not include` failures
                         2.000  i/100ms
New `to include` failures
                         1.000  i/100ms
-------------------------------------------------
Old `to not include` failures
                         21.187  (± 4.7%) i/s -    106.000
New `to include` failures
                         19.899  (± 5.0%) i/s -    100.000

Comparison:
Old `to not include` failures:       21.2 i/s
New `to include` failures:       19.9 i/s - 1.06x slower
