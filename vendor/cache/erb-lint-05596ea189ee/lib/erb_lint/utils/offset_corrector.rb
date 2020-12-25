# frozen_string_literal: true

module ERBLint
  module Utils
    class OffsetCorrector
      def initialize(processed_source, corrector, offset, bound_range)
        @processed_source = processed_source
        @corrector = corrector
        @offset = offset
        @bound_range = bound_range
      end

      def remove(range)
        @corrector.remove(range_with_offset(range))
      end

      def insert_before(range, content)
        @corrector.insert_before(range_with_offset(range), content)
      end

      def insert_after(range, content)
        @corrector.insert_after(range_with_offset(range), content)
      end

      def replace(range, content)
        @corrector.replace(range_with_offset(range), content)
      end

      def remove_preceding(range, size)
        @corrector.remove_preceding(range_with_offset(range), size)
      end

      def remove_leading(range, size)
        @corrector.remove_leading(range_with_offset(range), size)
      end

      def remove_trailing(range, size)
        @corrector.remove_trailing(range_with_offset(range), size)
      end

      def range_with_offset(node_or_range)
        range = to_range(node_or_range)

        @processed_source.to_source_range(
          bound(@offset + range.begin_pos)..bound(@offset + (range.end_pos - 1))
        )
      end

      def bound(pos)
        [
          [pos, @bound_range.min].max,
          @bound_range.max,
        ].min
      end

      private

      def to_range(node_or_range)
        case node_or_range
        when ::RuboCop::AST::Node, ::Parser::Source::Comment
          node_or_range.loc.expression
        when ::Parser::Source::Range
          node_or_range
        else
          raise TypeError,
            'Expected a Parser::Source::Range, Comment or ' \
                        "Rubocop::AST::Node, got #{node_or_range.class}"
        end
      end
    end
  end
end
