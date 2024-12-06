module Polyamorous
  module ReflectionExtensions
    def join_scope(table, foreign_table, foreign_klass)
     if respond_to?(:polymorphic?) && polymorphic?
        super.where!(foreign_table[foreign_type].eq(klass.name))
      else
        super
      end
    end
  end
end
