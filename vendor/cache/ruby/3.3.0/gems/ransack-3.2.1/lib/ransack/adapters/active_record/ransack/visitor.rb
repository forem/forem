module Ransack
  class Visitor
    def visit_and(object)
      nodes = object.values.map { |o| accept(o) }.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        Arel::Nodes::Grouping.new(Arel::Nodes::And.new(nodes))
      else
        nodes.first
      end
    end

    def quoted?(object)
      case object
      when Arel::Nodes::SqlLiteral, Bignum, Fixnum
        false
      else
        true
      end
    end

    def visit_Ransack_Nodes_Sort(object)
      if object.valid?
        if object.attr.is_a?(Arel::Attributes::Attribute)
          object.attr.send(object.dir)
        else
          ordered(object)
        end
      else
        scope_name = :"sort_by_#{object.name}_#{object.dir}"
        scope_name if object.context.object.respond_to?(scope_name)
      end
    end

    private

      def ordered(object)
        case object.dir
        when 'asc'.freeze
          Arel::Nodes::Ascending.new(object.attr)
        when 'desc'.freeze
          Arel::Nodes::Descending.new(object.attr)
        end
      end
  end
end
