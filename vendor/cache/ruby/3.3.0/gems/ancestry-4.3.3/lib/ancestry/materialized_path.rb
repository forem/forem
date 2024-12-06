module Ancestry
  # store ancestry as grandparent_id/parent_id
  # root a=nil,id=1   children=id,id/%      == 1, 1/%
  # 3: a=1/2,id=3     children=a/id,a/id/%  == 1/2/3, 1/2/3/%
  module MaterializedPath
    def self.extended(base)
      base.send(:include, InstanceMethods)
    end

    def path_of(object)
      to_node(object).path
    end

    def roots
      where(arel_table[ancestry_column].eq(ancestry_root))
    end

    def ancestors_of(object)
      t = arel_table
      node = to_node(object)
      where(t[primary_key].in(node.ancestor_ids))
    end

    def inpath_of(object)
      t = arel_table
      node = to_node(object)
      where(t[primary_key].in(node.path_ids))
    end

    def children_of(object)
      t = arel_table
      node = to_node(object)
      where(t[ancestry_column].eq(node.child_ancestry))
    end

    # indirect = anyone who is a descendant, but not a child
    def indirects_of(object)
      t = arel_table
      node = to_node(object)
      where(t[ancestry_column].matches("#{node.child_ancestry}#{ancestry_delimiter}%", nil, true))
    end

    def descendants_of(object)
      where(descendant_conditions(object))
    end

    def descendants_by_ancestry(ancestry)
      t = arel_table
      t[ancestry_column].matches("#{ancestry}#{ancestry_delimiter}%", nil, true).or(t[ancestry_column].eq(ancestry))
    end

    def descendant_conditions(object)
      node = to_node(object)
      descendants_by_ancestry( node.child_ancestry )
    end

    def descendant_before_save_conditions(object)
      node = to_node(object)
      descendants_by_ancestry( node.child_ancestry_before_save )
    end

    def subtree_of(object)
      t = arel_table
      node = to_node(object)
      descendants_of(node).or(where(t[primary_key].eq(node.id)))
    end

    def siblings_of(object)
      t = arel_table
      node = to_node(object)
      where(t[ancestry_column].eq(node[ancestry_column].presence))
    end

    def ordered_by_ancestry(order = nil)
      if %w(mysql mysql2 sqlite sqlite3).include?(connection.adapter_name.downcase)
        reorder(arel_table[ancestry_column], order)
      elsif %w(postgresql oracleenhanced).include?(connection.adapter_name.downcase) && ActiveRecord::VERSION::STRING >= "6.1"
        reorder(Arel::Nodes::Ascending.new(arel_table[ancestry_column]).nulls_first, order)
      else
        reorder(
          Arel::Nodes::Ascending.new(Arel::Nodes::NamedFunction.new('COALESCE', [arel_table[ancestry_column], Arel.sql("''")])),
          order
        )
      end
    end

    def ordered_by_ancestry_and(order)
      ordered_by_ancestry(order)
    end

    def ancestry_root
      nil
    end

    private

    def ancestry_validation_options
      {
        format: { with: ancestry_format_regexp },
        allow_nil: ancestry_nil_allowed?
      }
    end

    def ancestry_nil_allowed?
      true
    end

    def ancestry_format_regexp
      /\A#{ancestry_primary_key_format}(#{Regexp.escape(ancestry_delimiter)}#{ancestry_primary_key_format})*\z/.freeze
    end

    module InstanceMethods
      # optimization - better to go directly to column and avoid parsing
      def ancestors?
        read_attribute(self.ancestry_base_class.ancestry_column) != self.ancestry_base_class.ancestry_root
      end
      alias :has_parent? :ancestors?

      def ancestor_ids=(value)
        write_attribute(self.ancestry_base_class.ancestry_column, generate_ancestry(value))
      end

      def ancestor_ids
        parse_ancestry_column(read_attribute(self.ancestry_base_class.ancestry_column))
      end

      def ancestor_ids_in_database
        parse_ancestry_column(attribute_in_database(self.class.ancestry_column))
      end

      def ancestor_ids_before_last_save
        parse_ancestry_column(attribute_before_last_save(self.ancestry_base_class.ancestry_column))
      end

      def parent_id_in_database
        parse_ancestry_column(attribute_in_database(self.class.ancestry_column)).last
      end

      def parent_id_before_last_save
        parse_ancestry_column(attribute_before_last_save(self.ancestry_base_class.ancestry_column)).last
      end

      # optimization - better to go directly to column and avoid parsing
      def sibling_of?(node)
        self.read_attribute(self.ancestry_base_class.ancestry_column) == node.read_attribute(self.ancestry_base_class.ancestry_column)
      end

      # private (public so class methods can find it)
      # The ancestry value for this record's children (before save)
      # This is technically child_ancestry_was
      def child_ancestry
        # New records cannot have children
        raise Ancestry::AncestryException.new(I18n.t("ancestry.no_child_for_new_record")) if new_record?
        [attribute_in_database(self.ancestry_base_class.ancestry_column), id].compact.join(self.ancestry_base_class.ancestry_delimiter)
      end

      def child_ancestry_before_save
        # New records cannot have children
        raise Ancestry::AncestryException.new(I18n.t("ancestry.no_child_for_new_record")) if new_record?
        [attribute_before_last_save(self.ancestry_base_class.ancestry_column), id].compact.join(self.ancestry_base_class.ancestry_delimiter)
      end

      def parse_ancestry_column(obj)
        return [] if obj.nil? || obj == self.ancestry_base_class.ancestry_root
        obj_ids = obj.split(self.ancestry_base_class.ancestry_delimiter).delete_if(&:blank?)
        self.class.primary_key_is_an_integer? ? obj_ids.map!(&:to_i) : obj_ids
      end

      def generate_ancestry(ancestor_ids)
        if ancestor_ids.present? && ancestor_ids.any?
          ancestor_ids.join(self.ancestry_base_class.ancestry_delimiter)
        else
          self.ancestry_base_class.ancestry_root
        end
      end
    end
  end
end
