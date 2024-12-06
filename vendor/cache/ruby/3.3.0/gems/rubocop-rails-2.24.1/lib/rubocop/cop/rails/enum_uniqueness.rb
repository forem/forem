# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for duplicate values in enum declarations.
      #
      # @example
      #   # bad
      #   enum status: { active: 0, archived: 0 }
      #
      #   # good
      #   enum status: { active: 0, archived: 1 }
      #
      #   # bad
      #   enum status: [:active, :archived, :active]
      #
      #   # good
      #   enum status: [:active, :archived]
      class EnumUniqueness < Base
        include Duplication

        MSG = 'Duplicate value `%<value>s` found in `%<enum>s` enum declaration.'
        RESTRICT_ON_SEND = %i[enum].freeze

        def_node_matcher :enum?, <<~PATTERN
          (send nil? :enum (hash $...))
        PATTERN

        def_node_matcher :enum_values, <<~PATTERN
          (pair $_ ${array hash})
        PATTERN

        def on_send(node)
          enum?(node) do |pairs|
            pairs.each do |pair|
              enum_values(pair) do |key, args|
                items = args.values

                next unless duplicates?(items)

                consecutive_duplicates(items).each do |item|
                  add_offense(item, message: format(MSG, value: item.source, enum: enum_name(key)))
                end
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
      end
    end
  end
end
