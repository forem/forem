require 'ransack/visitor'

module Ransack
  class Context
    attr_reader :arel_visitor

    class << self

      def for_class(klass, options = {})
        if klass < ActiveRecord::Base
          Adapters::ActiveRecord::Context.new(klass, options)
        end
      end

      def for_object(object, options = {})
        case object
        when ActiveRecord::Relation
          Adapters::ActiveRecord::Context.new(object.klass, options)
        end
      end

    end # << self

    def initialize(object, options = {})
      @object = relation_for(object)
      @klass = @object.klass
      @join_dependency = join_dependency(@object)
      @join_type = options[:join_type] || Polyamorous::OuterJoin
      @search_key = options[:search_key] || Ransack.options[:search_key]
      @associations_pot = {}
      @tables_pot = {}
      @lock_associations = []

      @base = @join_dependency.instance_variable_get(:@join_root)
    end

    def bind_pair_for(key)
      @bind_pairs ||= {}

      @bind_pairs[key] ||= begin
        parent, attr_name = get_parent_and_attribute_name(key.to_s)
        [parent, attr_name] if parent && attr_name
      end
    end

    def klassify(obj)
      if Class === obj && ::ActiveRecord::Base > obj
        obj
      elsif obj.respond_to? :klass
        obj.klass
      else
        raise ArgumentError, "Don't know how to klassify #{obj.inspect}"
      end
    end
  end
end
