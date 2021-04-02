require "request_store"

# Completely remove original implementation
RailsSettings.__send__(:remove_const, :RequestCache)

module RailsSettings
  class Base < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    def self.inherited(subclass)
      super
      subclass_cache_key = subclass.name.underscore.tr("/", "_")

      # Define a unique RequestCache class for each settings klass
      request_cache = Class.new(BasicObject) do
        define_singleton_method(:cache_key) do
          scope = [subclass_cache_key]
          scope << @cache_prefix.call if @cache_prefix
          scope.join("/")
        end

        def self.settings
          RequestStore.store[cache_key]
        end

        def self.settings=(val)
          RequestStore.store[cache_key] = val
        end

        def self.reset
          self.settings = nil
        end
      end
      subclass.const_set(:RequestCache, request_cache)

      # Override existing methods to use the local RequestCache class
      subclass.instance_eval do
        define_singleton_method(:cache_key) { subclass::RequestCache.cache_key }

        define_singleton_method(:clear_cache) do
          subclass::RequestCache.reset
          Rails.cache.delete(cache_key)
        end

        define_singleton_method(:_all_settings) do
          subclass::RequestCache.settings ||=
            Rails.cache.fetch(cache_key, expires_in: 1.week) do
              vars = unscoped.select("var, value")
              result = {}
              vars.each { |record| result[record.var] = record.value }
              result.with_indifferent_access
            end
        end

        singleton_class.instance_eval { private :_all_settings }
      end
    end
  end
end
