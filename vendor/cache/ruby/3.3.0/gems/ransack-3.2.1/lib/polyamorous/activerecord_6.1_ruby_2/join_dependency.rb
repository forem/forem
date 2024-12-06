module Polyamorous
  module JoinDependencyExtensions
    # Replaces ActiveRecord::Associations::JoinDependency#build
    def build(associations, base_klass)
      associations.map do |name, right|
        if name.is_a? Join
          reflection = find_reflection base_klass, name.name
          reflection.check_validity!
          reflection.check_eager_loadable!

          klass = if reflection.polymorphic?
            name.klass || base_klass
          else
            reflection.klass
          end
          JoinAssociation.new(reflection, build(right, klass), name.klass, name.type)
        else
          reflection = find_reflection base_klass, name
          reflection.check_validity!
          reflection.check_eager_loadable!

          if reflection.polymorphic?
            raise ActiveRecord::EagerLoadPolymorphicError.new(reflection)
          end
          JoinAssociation.new(reflection, build(right, reflection.klass))
        end
      end
    end

    def join_constraints(joins_to_add, alias_tracker, references)
      @alias_tracker = alias_tracker
      @joined_tables = {}
      @references = {}

      references.each do |table_name|
        @references[table_name.to_sym] = table_name if table_name.is_a?(String)
      end

      joins = make_join_constraints(join_root, join_type)

      joins.concat joins_to_add.flat_map { |oj|
        if join_root.match?(oj.join_root) && join_root.table.name == oj.join_root.table.name
          walk join_root, oj.join_root, oj.join_type
        else
          make_join_constraints(oj.join_root, oj.join_type)
        end
      }
    end

    def construct_tables_for_association!(join_root, association)
      tables = table_aliases_for(join_root, association)
      association.table = tables.first
      tables
    end

    private

    def table_aliases_for(parent, node)
      node.reflection.chain.map { |reflection|
        alias_tracker.aliased_table_for(reflection.klass.arel_table) do
          root = reflection == node.reflection
          name = reflection.alias_candidate(parent.table_name)
          root ? name : "#{name}_join"
        end
      }
    end

    module ClassMethods
      # Prepended before ActiveRecord::Associations::JoinDependency#walk_tree
      #
      def walk_tree(associations, hash)
        case associations
        when TreeNode
          associations.add_to_tree(hash)
        when Hash
          associations.each do |k, v|
            cache =
              if TreeNode === k
                k.add_to_tree(hash)
              else
                hash[k] ||= {}
              end
            walk_tree(v, cache)
          end
        else
          super(associations, hash)
        end
      end
    end

  end
end
