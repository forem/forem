# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Prefer using `distinct` before `pluck` instead of `uniq` after `pluck`.
      #
      # The use of distinct before pluck is preferred because it executes by
      # the database.
      #
      # This cop has two different enforcement modes. When the EnforcedStyle
      # is `conservative` (the default), then only calls to `pluck` on a constant
      # (i.e. a model class) before `uniq` are added as offenses.
      #
      # When the EnforcedStyle is `aggressive` then all calls to `pluck` before
      # distinct are added as offenses. This may lead to false positives
      # as the cop cannot distinguish between calls to `pluck` on an
      # ActiveRecord::Relation vs a call to pluck on an
      # ActiveRecord::Associations::CollectionProxy.
      #
      # @safety
      #   This cop is unsafe for autocorrection because the behavior may change
      #   depending on the database collation.
      #
      # @example EnforcedStyle: conservative (default)
      #   # bad - redundantly fetches duplicate values
      #   Album.pluck(:band_name).uniq
      #
      #   # good
      #   Album.distinct.pluck(:band_name)
      #
      # @example EnforcedStyle: aggressive
      #   # bad - redundantly fetches duplicate values
      #   Album.pluck(:band_name).uniq
      #
      #   # bad - redundantly fetches duplicate values
      #   Album.where(year: 1985).pluck(:band_name).uniq
      #
      #   # bad - redundantly fetches duplicate values
      #   customer.favourites.pluck(:color).uniq
      #
      #   # good
      #   Album.distinct.pluck(:band_name)
      #   Album.distinct.where(year: 1985).pluck(:band_name)
      #   customer.favourites.distinct.pluck(:color)
      #
      class UniqBeforePluck < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `distinct` before `pluck`.'
        RESTRICT_ON_SEND = %i[uniq].freeze
        NEWLINE = "\n"
        PATTERN = '[!^block (send (send %<type>s :pluck ...) :uniq ...)]'

        def_node_matcher :conservative_node_match, format(PATTERN, type: 'const')

        def_node_matcher :aggressive_node_match, format(PATTERN, type: '_')

        def on_send(node)
          uniq = if style == :conservative
                   conservative_node_match(node)
                 else
                   aggressive_node_match(node)
                 end

          return unless uniq

          add_offense(node.loc.selector) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          method = node.method_name

          corrector.remove(dot_method_with_whitespace(method, node))
          if (dot = node.receiver.loc.dot)
            corrector.insert_before(dot.begin, '.distinct')
          else
            corrector.insert_before(node.receiver, 'distinct.')
          end
        end

        def dot_method_with_whitespace(method, node)
          range_between(dot_method_begin_pos(method, node), node.loc.selector.end_pos)
        end

        def dot_method_begin_pos(method, node)
          lines = node.source.split(NEWLINE)

          if lines.last.strip == ".#{method}"
            node.source.rindex(NEWLINE)
          else
            node.loc.dot.begin_pos
          end
        end
      end
    end
  end
end
