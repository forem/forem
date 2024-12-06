# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for enums written with array syntax.
      #
      # When using array syntax, adding an element in a
      # position other than the last causes all previous
      # definitions to shift. Explicitly specifying the
      # value for each key prevents this from happening.
      #
      # @example
      #   # bad
      #   enum status: [:active, :archived]
      #
      #   # good
      #   enum status: { active: 0, archived: 1 }
      #
      class EnumHash < Base
        extend AutoCorrector

        MSG = 'Enum defined as an array found in `%<enum>s` enum declaration. Use hash syntax instead.'
        RESTRICT_ON_SEND = %i[enum].freeze

        def_node_matcher :enum?, <<~PATTERN
          (send nil? :enum (hash $...))
        PATTERN

        def_node_matcher :array_pair?, <<~PATTERN
          (pair $_ $array)
        PATTERN

        def on_send(node)
          enum?(node) do |pairs|
            pairs.each do |pair|
              key, array = array_pair?(pair)
              next unless key

              add_offense(array, message: format(MSG, enum: enum_name(key))) do |corrector|
                hash = array.children.each_with_index.map do |elem, index|
                  "#{source(elem)} => #{index}"
                end.join(', ')

                corrector.replace(array, "{#{hash}}")
              end
            end
          end
        end

        private

        def enum_name(key)
          case key.type
          when :sym, :str
            key.value
          else
            key.source
          end
        end

        def source(elem)
          case elem.type
          when :str
            elem.value.dump
          when :sym
            elem.value.inspect
          else
            elem.source
          end
        end
      end
    end
  end
end
