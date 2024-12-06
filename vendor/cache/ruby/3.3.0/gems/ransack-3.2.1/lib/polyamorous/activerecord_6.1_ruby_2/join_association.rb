module Polyamorous
  module JoinAssociationExtensions
    include SwappingReflectionClass
    def self.prepended(base)
      base.class_eval { attr_reader :join_type }
    end

    def initialize(reflection, children, polymorphic_class = nil, join_type = Arel::Nodes::InnerJoin)
      @join_type = join_type
      if polymorphic_class && ::ActiveRecord::Base > polymorphic_class
        swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
          super(reflection, children)
          self.reflection.options[:polymorphic] = true
        end
      else
        super(reflection, children)
      end
    end

    # Same as #join_constraints, but instead of constructing tables from the
    # given block, uses the ones passed
    def join_constraints_with_tables(foreign_table, foreign_klass, join_type, alias_tracker, tables)
      joins = []
      chain = []

      reflection.chain.each.with_index do |reflection, i|
        table = tables[i]

        @table ||= table
        chain << [reflection, table]
      end

      # The chain starts with the target table, but we want to end with it here (makes
      # more sense in this context), so we reverse
      chain.reverse_each do |reflection, table|
        klass = reflection.klass

        join_scope = reflection.join_scope(table, foreign_table, foreign_klass)

        unless join_scope.references_values.empty?
          join_dependency = join_scope.construct_join_dependency(
            join_scope.eager_load_values | join_scope.includes_values, Arel::Nodes::OuterJoin
          )
          join_scope.joins!(join_dependency)
        end

        arel = join_scope.arel(alias_tracker.aliases)
        nodes = arel.constraints.first

        if nodes.is_a?(Arel::Nodes::And)
          others = nodes.children.extract! do |node|
            !Arel.fetch_attribute(node) { |attr| attr.relation.name == table.name }
          end
        end

        joins << table.create_join(table, table.create_on(nodes), join_type)

        if others && !others.empty?
          joins.concat arel.join_sources
          append_constraints(joins.last, others)
        end

        # The current table in this iteration becomes the foreign table in the next
        foreign_table, foreign_klass = table, klass
      end

      joins
    end
  end
end
