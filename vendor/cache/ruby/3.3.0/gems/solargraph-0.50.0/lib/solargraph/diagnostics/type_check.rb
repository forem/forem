# frozen_string_literal: true

module Solargraph
  module Diagnostics
    # TypeCheck reports methods with undefined return types, untagged
    # parameters, and invalid param tags.
    #
    class TypeCheck < Base
      def diagnose source, api_map
        # return [] unless args.include?('always') || api_map.workspaced?(source.filename)
        severity = Diagnostics::Severities::ERROR
        level = (args.reverse.find { |a| ['normal', 'typed', 'strict', 'strong'].include?(a) }) || :normal
        checker = Solargraph::TypeChecker.new(source.filename, api_map: api_map, level: level.to_sym)
        checker.problems
          .sort { |a, b| a.location.range.start.line <=> b.location.range.start.line }
          .map do |problem|
            {
              range: extract_first_line(problem.location, source),
              severity: severity,
              source: 'Typecheck',
              message: problem.message
            }
          end
      end

      private

      # @param location [Location]
      # @param source [Source]
      # @return [Hash]
      def extract_first_line location, source
        return location.range.to_hash if location.range.start.line == location.range.ending.line
        {
          start: {
            line: location.range.start.line,
            character: location.range.start.character
          },
          end: {
            line: location.range.start.line,
            character: last_character(location.range.start, source)
          }
        }
      end

      # @param position [Solargraph::Position]
      # @param source [Solargraph::Source]
      # @return [Integer]
      def last_character position, source
        cursor = Position.to_offset(source.code, position)
        source.code.index(/[\r\n]/, cursor) || source.code.length
      end
    end
  end
end
