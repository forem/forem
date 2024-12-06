# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces the use of `pluck` over `map`.
      #
      # `pluck` can be used instead of `map` to extract a single key from each
      # element in an enumerable. When called on an Active Record relation, it
      # results in a more efficient query that only selects the necessary key.
      #
      # @safety
      #   This cop is unsafe because model can use column aliases.
      #
      #   [source,ruby]
      #   ----
      #   # Original code
      #   User.select('name AS nickname').map { |user| user[:nickname] } # => array of nicknames
      #
      #   # After autocorrection
      #   User.select('name AS nickname').pluck(:nickname) # => raises ActiveRecord::StatementInvalid
      #   ----
      #
      # @example
      #   # bad
      #   Post.published.map { |post| post[:title] }
      #   [{ a: :b, c: :d }].collect { |el| el[:a] }
      #
      #   # good
      #   Post.published.pluck(:title)
      #   [{ a: :b, c: :d }].pluck(:a)
      class Pluck < Base
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Prefer `%<replacement>s` over `%<current>s`.'

        minimum_target_rails_version 5.0

        def_node_matcher :pluck_candidate?, <<~PATTERN
          ({block numblock} (call _ {:map :collect}) $_argument (send lvar :[] $_key))
        PATTERN

        def on_block(node)
          pluck_candidate?(node) do |argument, key|
            next if key.regexp_type? || !use_one_block_argument?(argument)

            match = if node.block_type?
                      block_argument = argument.children.first.source
                      use_block_argument_in_key?(block_argument, key)
                    else # numblock
                      argument == 1 && use_block_argument_in_key?('_1', key)
                    end
            next unless match

            register_offense(node, key)
          end
        end
        alias on_numblock on_block

        private

        def use_one_block_argument?(argument)
          return true if argument == 1 # Checks for numbered argument `_1`.

          argument.respond_to?(:one?) && argument.one?
        end

        def use_block_argument_in_key?(block_argument, key)
          return false if block_argument == key.source

          key.each_descendant(:lvar).none? { |lvar| block_argument == lvar.source }
        end

        def offense_range(node)
          node.send_node.loc.selector.join(node.loc.end)
        end

        def register_offense(node, key)
          replacement = "pluck(#{key.source})"
          message = message(replacement, node)

          add_offense(offense_range(node), message: message) do |corrector|
            corrector.replace(offense_range(node), replacement)
          end
        end

        def message(replacement, node)
          current = offense_range(node).source

          format(MSG, replacement: replacement, current: current)
        end
      end
    end
  end
end
