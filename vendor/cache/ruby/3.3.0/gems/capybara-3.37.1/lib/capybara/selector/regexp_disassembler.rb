# frozen_string_literal: true

require 'regexp_parser'

module Capybara
  class Selector
    # @api private
    class RegexpDisassembler
      def initialize(regexp)
        @regexp = regexp
      end

      def alternated_substrings
        @alternated_substrings ||= begin
          or_strings = process(alternation: true)
          remove_or_covered(or_strings)
          or_strings.any?(&:empty?) ? [] : or_strings
        end
      end

      def substrings
        @substrings ||= begin
          strs = process(alternation: false).first
          remove_and_covered(strs)
        end
      end

    private

      def remove_and_covered(strings)
        # delete_if is documented to modify the array after every block iteration - this doesn't appear to be true
        # uniq the strings to prevent identical strings from removing each other
        strings.uniq!

        # If we have "ab" and "abcd" required - only need to check for "abcd"
        strings.delete_if do |sub_string|
          strings.any? do |cover_string|
            next if sub_string.equal? cover_string

            cover_string.include?(sub_string)
          end
        end
      end

      def remove_or_covered(or_series)
        # If we are going to match `("a" and "b") or ("ade" and "bce")` it only makes sense to match ("a" and "b")

        # Ensure minimum sets of strings are being or'd
        or_series.each { |strs| remove_and_covered(strs) }

        # Remove any of the alternated string series that fully contain any other string series
        or_series.delete_if do |and_strs|
          or_series.any? do |and_strs2|
            next if and_strs.equal? and_strs2

            remove_and_covered(and_strs + and_strs2) == and_strs
          end
        end
      end

      def process(alternation:)
        strs = extract_strings(Regexp::Parser.parse(@regexp), alternation: alternation)
        strs = collapse(combine(strs).map(&:flatten))
        strs.each { |str| str.map!(&:upcase) } if @regexp.casefold?
        strs
      end

      def combine(strs)
        suffixes = [[]]
        strs.reverse_each do |str|
          if str.is_a? Set
            prefixes = str.each_with_object([]) { |s, memo| memo.concat combine(s) }

            result = []
            prefixes.product(suffixes) { |pair| result << pair.flatten(1) }
            suffixes = result
          else
            suffixes.each { |arr| arr.unshift str }
          end
        end
        suffixes
      end

      def collapse(strs)
        strs.map do |substrings|
          substrings.slice_before(&:nil?).map(&:join).reject(&:empty?).uniq
        end
      end

      def extract_strings(expression, alternation: false)
        Expression.new(expression).extract_strings(alternation)
      end

      # @api private
      class Expression
        def initialize(exp)
          @exp = exp
        end

        def extract_strings(process_alternatives)
          strings = []
          each do |exp|
            next if exp.ignore?

            next strings.push(nil) if exp.optional? && !process_alternatives

            next strings.push(exp.alternative_strings) if exp.alternation? && process_alternatives

            strings.concat(exp.strings(process_alternatives))
          end
          strings
        end

      protected

        def alternation?
          (type == :meta) && !terminal?
        end

        def optional?
          min_repeat.zero?
        end

        def terminal?
          @exp.terminal?
        end

        def strings(process_alternatives)
          if indeterminate?
            [nil]
          elsif terminal?
            terminal_strings
          elsif optional?
            optional_strings
          else
            repeated_strings(process_alternatives)
          end
        end

        def terminal_strings
          text = case @exp.type
          when :literal then @exp.text
          when :escape then @exp.char
          else
            return [nil]
          end

          optional? ? options_set(text) : repeat_set(text)
        end

        def optional_strings
          options_set(extract_strings(true))
        end

        def repeated_strings(process_alternatives)
          repeat_set extract_strings(process_alternatives)
        end

        def alternative_strings
          alts = alternatives.map { |sub_exp| sub_exp.extract_strings(alternation: true) }
          alts.all?(&:any?) ? Set.new(alts) : nil
        end

        def ignore?
          [Regexp::Expression::Assertion::NegativeLookahead,
           Regexp::Expression::Assertion::NegativeLookbehind].any? { |klass| @exp.is_a? klass }
        end

      private

        def indeterminate?
          %i[meta set].include?(type)
        end

        def min_repeat
          @exp.repetitions.begin
        end

        def max_repeat
          @exp.repetitions.end
        end

        def fixed_repeat?
          min_repeat == max_repeat
        end

        def type
          @exp.type
        end

        def repeat_set(str)
          strs = Array(str * min_repeat)
          strs.push(nil) unless fixed_repeat?
          strs
        end

        def options_set(strs)
          strs = [Set.new([[''], Array(strs)])]
          strs.push(nil) unless max_repeat == 1
          strs
        end

        def alternatives
          @exp.alternatives.map { |exp| Expression.new(exp) }
        end

        def each
          @exp.each { |exp| yield Expression.new(exp) }
        end
      end
      private_constant :Expression
    end
  end
end
