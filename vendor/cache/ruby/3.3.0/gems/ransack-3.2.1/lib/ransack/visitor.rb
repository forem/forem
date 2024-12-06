module Ransack
  class Visitor

    def accept(object)
      visit(object)
    end

    def can_accept?(object)
      respond_to? DISPATCH[object.class]
    end

    def visit_Array(object)
      object.map { |o| accept(o) }.compact
    end

    def visit_Ransack_Nodes_Condition(object)
      object.arel_predicate if object.valid?
    end

    def visit_Ransack_Nodes_Grouping(object)
      if object.combinator == Constants::OR
        visit_or(object)
      else
        visit_and(object)
      end
    end

    def visit_and(object)
      raise "not implemented"
    end

    def visit_or(object)
      nodes = object.values.map { |o| accept(o) }.compact
      nodes.inject(&:or)
    end

    def quoted?(object)
      raise "not implemented"
    end

    def visit(object)
      send(DISPATCH[object.class], object)
    end

    DISPATCH = Hash.new do |hash, klass|
      hash[klass] = "visit_#{
        klass.name.gsub(Constants::TWO_COLONS, Constants::UNDERSCORE)
        }"
    end
  end
end
