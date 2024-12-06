# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Sort RSpec metadata alphabetically.
      #
      # @example
      #   # bad
      #   describe 'Something', :b, :a
      #   context 'Something', foo: 'bar', baz: true
      #   it 'works', :b, :a, foo: 'bar', baz: true
      #
      #   # good
      #   describe 'Something', :a, :b
      #   context 'Something', baz: true, foo: 'bar'
      #   it 'works', :a, :b, baz: true, foo: 'bar'
      #
      class SortMetadata < Base
        extend AutoCorrector
        include Metadata
        include RangeHelp

        MSG = 'Sort metadata alphabetically.'

        def on_metadata(symbols, hash)
          pairs = hash&.pairs || []
          return if sorted?(symbols, pairs)

          crime_scene = crime_scene(symbols, pairs)
          add_offense(crime_scene) do |corrector|
            corrector.replace(crime_scene, replacement(symbols, pairs))
          end
        end

        private

        def crime_scene(symbols, pairs)
          metadata = symbols + pairs

          range_between(
            metadata.first.source_range.begin_pos,
            metadata.last.source_range.end_pos
          )
        end

        def replacement(symbols, pairs)
          (sort_symbols(symbols) + sort_pairs(pairs)).map(&:source).join(', ')
        end

        def sorted?(symbols, pairs)
          symbols == sort_symbols(symbols) && pairs == sort_pairs(pairs)
        end

        def sort_pairs(pairs)
          pairs.sort_by { |pair| pair.key.source.downcase }
        end

        def sort_symbols(symbols)
          symbols.sort_by do |symbol|
            if %i[str sym].include?(symbol.type)
              symbol.value.to_s.downcase
            else
              symbol.source.downcase
            end
          end
        end
      end
    end
  end
end
