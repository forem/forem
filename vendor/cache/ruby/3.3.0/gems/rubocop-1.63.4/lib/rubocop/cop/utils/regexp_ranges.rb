# frozen_string_literal: true

module RuboCop
  module Cop
    module Utils
      # Helper to abstract complexity of building range pairs
      # with octal escape reconstruction (needed for regexp_parser < 2.7).
      class RegexpRanges
        attr_reader :root

        def initialize(root)
          @root = root
          @compound_token = []
          @pairs = []
          @populated = false
        end

        def compound_token
          populate_all unless @populated

          @compound_token
        end

        def pairs
          populate_all unless @populated

          @pairs
        end

        private

        def populate_all
          populate(@root)

          # If either bound is a compound the first one is an escape
          # and that's all we need to work with.
          # If there are any cops that wanted to operate on the compound
          # expression we could wrap it with a facade class.
          @pairs.map! { |pair| pair.map(&:first) }

          @populated = true
        end

        def populate(expr)
          expressions = expr.expressions.to_a

          until expressions.empty?
            current = expressions.shift

            if escaped_octal?(current)
              @compound_token << current
              @compound_token.concat(pop_octal_digits(expressions))
              # If we have all the digits we can discard.
            end

            next unless current.type == :set

            process_set(expressions, current)
            @compound_token.clear
          end
        end

        def process_set(expressions, current)
          case current.token
          when :range
            @pairs << compose_range(expressions, current)
          when :character
            # Child expressions may include the range we are looking for.
            populate(current)
          when :intersection
            # Each child expression could have child expressions that lead to ranges.
            current.expressions.each do |intersected|
              populate(intersected)
            end
          end
        end

        def compose_range(expressions, current)
          range_start, range_end = current.expressions
          range_start = if @compound_token.size.between?(1, 2) && octal_digit?(range_start.text)
                          @compound_token.dup << range_start
                        else
                          [range_start]
                        end
          range_end = [range_end]
          range_end.concat(pop_octal_digits(expressions)) if escaped_octal?(range_end.first)
          [range_start, range_end]
        end

        def escaped_octal?(expr)
          expr.text.valid_encoding? && expr.text =~ /^\\[0-7]$/
        end

        def octal_digit?(char)
          ('0'..'7').cover?(char)
        end

        def pop_octal_digits(expressions)
          digits = []

          2.times do
            next unless (next_child = expressions.first)
            next unless next_child.type == :literal && next_child.text =~ /^[0-7]$/

            digits << expressions.shift
          end

          digits
        end
      end
    end
  end
end
