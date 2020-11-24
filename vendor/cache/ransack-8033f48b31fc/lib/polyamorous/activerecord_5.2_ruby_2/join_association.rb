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

    def ==(other)
      base_klass == other.base_klass
    end
  end
end
