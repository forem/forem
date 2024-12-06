module Ancestry
  # store ancestry as /grandparent_id/parent_id/
  # root: a=/,id=1    children=#{a}#{id}/% == /1/%
  # 3:    a=/1/2/,id=3 children=#{a}#{id}/% == /1/2/3/%
  module MaterializedPath2
    include MaterializedPath

    def self.extended(base)
      base.send(:include, MaterializedPath::InstanceMethods)
      base.send(:include, InstanceMethods)
    end

    def indirects_of(object)
      t = arel_table
      node = to_node(object)
      where(t[ancestry_column].matches("#{node.child_ancestry}%#{ancestry_delimiter}%", nil, true))
    end

    def ordered_by_ancestry(order = nil)
      reorder(Arel::Nodes::Ascending.new(arel_table[ancestry_column]), order)
    end

    def descendants_by_ancestry(ancestry)
      arel_table[ancestry_column].matches("#{ancestry}%", nil, true)
    end

    def ancestry_root
      ancestry_delimiter
    end

    private

    def ancestry_nil_allowed?
      false
    end

    def ancestry_format_regexp
      /\A#{Regexp.escape(ancestry_delimiter)}(#{ancestry_primary_key_format}#{Regexp.escape(ancestry_delimiter)})*\z/.freeze
    end

    module InstanceMethods
      def child_ancestry
        # New records cannot have children
        raise Ancestry::AncestryException.new(I18n.t("ancestry.no_child_for_new_record")) if new_record?
        "#{attribute_in_database(self.ancestry_base_class.ancestry_column)}#{id}#{self.ancestry_base_class.ancestry_delimiter}"
      end

      def child_ancestry_before_save
        # New records cannot have children
        raise Ancestry::AncestryException.new(I18n.t("ancestry.no_child_for_new_record")) if new_record?
        "#{attribute_before_last_save(self.ancestry_base_class.ancestry_column)}#{id}#{self.ancestry_base_class.ancestry_delimiter}"
      end

      def generate_ancestry(ancestor_ids)
        if ancestor_ids.present? && ancestor_ids.any?
          "#{self.ancestry_base_class.ancestry_delimiter}#{ancestor_ids.join(self.ancestry_base_class.ancestry_delimiter)}#{self.ancestry_base_class.ancestry_delimiter}"
        else
          self.ancestry_base_class.ancestry_root
        end
      end
    end
  end
end
