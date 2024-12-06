# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies places where manually constructed SQL
      # in `where` can be replaced with `where(attribute: value)`.
      #
      # @safety
      #   This cop's autocorrection is unsafe because is may change SQL.
      #   See: https://github.com/rubocop/rubocop-rails/issues/403
      #
      # @example
      #   # bad
      #   User.where('name = ?', 'Gabe')
      #   User.where('name = :name', name: 'Gabe')
      #   User.where('name IS NULL')
      #   User.where('name IN (?)', ['john', 'jane'])
      #   User.where('name IN (:names)', names: ['john', 'jane'])
      #   User.where('users.name = :name', name: 'Gabe')
      #
      #   # good
      #   User.where(name: 'Gabe')
      #   User.where(name: nil)
      #   User.where(name: ['john', 'jane'])
      #   User.where(users: { name: 'Gabe' })
      class WhereEquals < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of manually constructing SQL.'
        RESTRICT_ON_SEND = %i[where].freeze

        def_node_matcher :where_method_call?, <<~PATTERN
          {
            (call _ :where (array $str_type? $_ ?))
            (call _ :where $str_type? $_ ?)
          }
        PATTERN

        def on_send(node)
          where_method_call?(node) do |template_node, value_node|
            value_node = value_node.first

            range = offense_range(node)

            column_and_value = extract_column_and_value(template_node, value_node)
            return unless column_and_value

            good_method = build_good_method(*column_and_value)
            message = format(MSG, good_method: good_method)

            add_offense(range, message: message) do |corrector|
              corrector.replace(range, good_method)
            end
          end
        end
        alias on_csend on_send

        EQ_ANONYMOUS_RE = /\A([\w.]+)\s+=\s+\?\z/.freeze             # column = ?
        IN_ANONYMOUS_RE = /\A([\w.]+)\s+IN\s+\(\?\)\z/i.freeze       # column IN (?)
        EQ_NAMED_RE     = /\A([\w.]+)\s+=\s+:(\w+)\z/.freeze         # column = :column
        IN_NAMED_RE     = /\A([\w.]+)\s+IN\s+\(:(\w+)\)\z/i.freeze   # column IN (:column)
        IS_NULL_RE      = /\A([\w.]+)\s+IS\s+NULL\z/i.freeze         # column IS NULL

        private

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end

        def extract_column_and_value(template_node, value_node)
          value =
            case template_node.value
            when EQ_ANONYMOUS_RE, IN_ANONYMOUS_RE
              value_node.source
            when EQ_NAMED_RE, IN_NAMED_RE
              return unless value_node&.hash_type?

              pair = value_node.pairs.find { |p| p.key.value.to_sym == Regexp.last_match(2).to_sym }
              pair.value.source
            when IS_NULL_RE
              'nil'
            else
              return
            end

          [Regexp.last_match(1), value]
        end

        def build_good_method(column, value)
          if column.include?('.')
            table, column = column.split('.')

            "where(#{table}: { #{column}: #{value} })"
          else
            "where(#{column}: #{value})"
          end
        end
      end
    end
  end
end
