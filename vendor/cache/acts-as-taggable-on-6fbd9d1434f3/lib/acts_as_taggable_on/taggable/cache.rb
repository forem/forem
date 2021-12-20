# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module Cache
      def self.included(base)
        # When included, conditionally adds tag caching methods when the model
        #   has any "cached_#{tag_type}_list" column
        base.extend Columns
      end

      module Columns
        # ActiveRecord::Base.columns makes a database connection and caches the
        #   calculated columns hash for the record as @columns.  Since we don't
        #   want to add caching methods until we confirm the presence of a
        #   caching column, and we don't want to force opening a database
        #   connection when the class is loaded, here we intercept and cache
        #   the call to :columns as @acts_as_taggable_on_cache_columns
        #   to mimic the underlying behavior.  While processing this first
        #   call to columns, we do the caching column check and dynamically add
        #   the class and instance methods
        #   FIXME: this method cannot compile in rubinius
        def columns
          @acts_as_taggable_on_cache_columns ||= begin
            db_columns = super
            _add_tags_caching_methods if _has_tags_cache_columns?(db_columns)
            db_columns
          end
        end

        def reset_column_information
          super
          @acts_as_taggable_on_cache_columns = nil
        end

        private

        # @private
        def _has_tags_cache_columns?(db_columns)
          db_column_names = db_columns.map(&:name)
          tag_types.any? do |context|
            db_column_names.include?("cached_#{context.to_s.singularize}_list")
          end
        end

        # @private
        def _add_tags_caching_methods
          send :include, ActsAsTaggableOn::Taggable::Cache::InstanceMethods
          extend ActsAsTaggableOn::Taggable::Cache::ClassMethods

          before_save :save_cached_tag_list

          initialize_tags_cache
        end
      end

      module ClassMethods
        def initialize_tags_cache
          tag_types.map(&:to_s).each do |tag_type|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.caching_#{tag_type.singularize}_list?
              caching_tag_list_on?("#{tag_type}")
            end
            RUBY
          end
        end

        def acts_as_taggable_on(*args)
          super(*args)
          initialize_tags_cache
        end

        def caching_tag_list_on?(context)
          column_names.include?("cached_#{context.to_s.singularize}_list")
        end
      end

      module InstanceMethods
        def save_cached_tag_list
          tag_types.map(&:to_s).each do |tag_type|
            if self.class.send("caching_#{tag_type.singularize}_list?") && tag_list_cache_set_on(tag_type)
              list = tag_list_cache_on(tag_type).to_a.flatten.compact.join("#{ActsAsTaggableOn.delimiter} ")
              self["cached_#{tag_type.singularize}_list"] = list
            end
          end

          true
        end
      end
    end
  end
end
