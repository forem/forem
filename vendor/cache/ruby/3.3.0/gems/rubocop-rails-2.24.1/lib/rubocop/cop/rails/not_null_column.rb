# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for add_column call with NOT NULL constraint in migration file.
      #
      # `TEXT` can have default values in PostgreSQL, but not in MySQL.
      # It will automatically detect an adapter from `development` environment
      # in `config/database.yml` or the environment variable `DATABASE_URL`
      # when the `Database` option is not set. If the database is MySQL,
      # this cop ignores offenses for the `TEXT`.
      #
      # @example
      #   # bad
      #   add_column :users, :name, :string, null: false
      #   add_reference :products, :category, null: false
      #
      #   # good
      #   add_column :users, :name, :string, null: true
      #   add_column :users, :name, :string, null: false, default: ''
      #   add_reference :products, :category
      #   add_reference :products, :category, null: false, default: 1
      class NotNullColumn < Base
        include DatabaseTypeResolvable

        MSG = 'Do not add a NOT NULL column without a default value.'
        RESTRICT_ON_SEND = %i[add_column add_reference].freeze

        def_node_matcher :add_not_null_column?, <<~PATTERN
          (send nil? :add_column _ _ $_ (hash $...))
        PATTERN

        def_node_matcher :add_not_null_reference?, <<~PATTERN
          (send nil? :add_reference _ _ (hash $...))
        PATTERN

        def_node_matcher :null_false?, <<~PATTERN
          (pair (sym :null) (false))
        PATTERN

        def_node_matcher :default_option?, <<~PATTERN
          (pair (sym :default) !nil)
        PATTERN

        def on_send(node)
          check_add_column(node)
          check_add_reference(node)
        end

        private

        def check_add_column(node)
          add_not_null_column?(node) do |type, pairs|
            if type.respond_to?(:value)
              return if type.value == :virtual || type.value == 'virtual'
              return if (type.value == :text || type.value == 'text') && database == MYSQL
            end

            check_pairs(pairs)
          end
        end

        def check_add_reference(node)
          add_not_null_reference?(node) do |pairs|
            check_pairs(pairs)
          end
        end

        def check_pairs(pairs)
          return if pairs.any? { |pair| default_option?(pair) }

          null_false = pairs.find { |pair| null_false?(pair) }
          return unless null_false

          add_offense(null_false)
        end
      end
    end
  end
end
