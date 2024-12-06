module Ancestry
  module HasAncestry
    def has_ancestry options = {}
      # Check options
      raise Ancestry::AncestryException.new(I18n.t("ancestry.option_must_be_hash")) unless options.is_a? Hash
      options.each do |key, value|
        unless [:ancestry_column, :orphan_strategy, :cache_depth, :depth_cache_column, :touch, :counter_cache, :primary_key_format, :update_strategy, :ancestry_format].include? key
          raise Ancestry::AncestryException.new(I18n.t("ancestry.unknown_option", key: key.inspect, value: value.inspect))
        end
      end

      if options[:ancestry_format].present? && ![:materialized_path, :materialized_path2].include?( options[:ancestry_format] )
        raise Ancestry::AncestryException.new(I18n.t("ancestry.unknown_format", value: options[:ancestry_format]))
      end

      # Create ancestry column accessor and set to option or default
      cattr_accessor :ancestry_column
      self.ancestry_column = options[:ancestry_column] || :ancestry

      cattr_accessor :ancestry_primary_key_format
      self.ancestry_primary_key_format = options[:primary_key_format].presence || Ancestry.default_primary_key_format

      cattr_accessor :ancestry_delimiter
      self.ancestry_delimiter = '/'

      # Save self as base class (for STI)
      cattr_accessor :ancestry_base_class
      self.ancestry_base_class = self

      # Touch ancestors after updating
      cattr_accessor :touch_ancestors
      self.touch_ancestors = options[:touch] || false

      # Include instance methods
      include Ancestry::InstanceMethods

      # Include dynamic class methods
      extend Ancestry::ClassMethods

      cattr_accessor :ancestry_format
      self.ancestry_format = options[:ancestry_format] || Ancestry.default_ancestry_format

      if ancestry_format == :materialized_path2
        extend Ancestry::MaterializedPath2
      else
        extend Ancestry::MaterializedPath
      end

      attribute self.ancestry_column, default: self.ancestry_root

      validates self.ancestry_column, ancestry_validation_options

      update_strategy = options[:update_strategy] || Ancestry.default_update_strategy
      include Ancestry::MaterializedPathPg if update_strategy == :sql

      # Create orphan strategy accessor and set to option or default (writer comes from DynamicClassMethods)
      cattr_reader :orphan_strategy
      self.orphan_strategy = options[:orphan_strategy] || :destroy

      # Validate that the ancestor ids don't include own id
      validate :ancestry_exclude_self

      # Update descendants with new ancestry after update
      after_update :update_descendants_with_new_ancestry

      # Apply orphan strategy before destroy
      before_destroy :apply_orphan_strategy

      # Create ancestry column accessor and set to option or default
      if options[:cache_depth]
        # Create accessor for column name and set to option or default
        self.cattr_accessor :depth_cache_column
        self.depth_cache_column = options[:depth_cache_column] || :ancestry_depth

        # Cache depth in depth cache column before save
        before_validation :cache_depth
        before_save :cache_depth

        # Validate depth column
        validates_numericality_of depth_cache_column, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => false
      end

      # Create counter cache column accessor and set to option or default
      if options[:counter_cache]
        cattr_accessor :counter_cache_column
        self.counter_cache_column = options[:counter_cache] == true ? 'children_count' : options[:counter_cache].to_s

        after_create :increase_parent_counter_cache, if: :has_parent?
        after_destroy :decrease_parent_counter_cache, if: :has_parent?
        after_update :update_parent_counter_cache
      end

      # Create named scopes for depth
      {:before_depth => '<', :to_depth => '<=', :at_depth => '=', :from_depth => '>=', :after_depth => '>'}.each do |scope_name, operator|
        scope scope_name, lambda { |depth|
          raise Ancestry::AncestryException.new(I18n.t("ancestry.named_scope_depth_cache",
                                                       :scope_name => scope_name
                                                       )) unless options[:cache_depth]
          where("#{depth_cache_column} #{operator} ?", depth)
        }
      end

      after_touch :touch_ancestors_callback
      after_destroy :touch_ancestors_callback
      after_save :touch_ancestors_callback, if: :saved_changes?
    end

    def acts_as_tree(*args)
      return super if defined?(super)
      has_ancestry(*args)
    end
  end
end

require 'active_support'
ActiveSupport.on_load :active_record do
  extend Ancestry::HasAncestry
end
