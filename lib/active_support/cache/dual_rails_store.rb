require 'active_support/cache'
require 'active_support/version'

module ActiveSupport
  module Cache
    class DualRailsStore < Store
      attr_reader :stores

      def initialize(store_options)
        @stores = store_options.each_with_object({}) do |(name, options), h|
          h[name] = ActiveSupport::Cache.lookup_store(options)
        end
        @options = {}
      end

      def cleanup(*args)
        raise 'Do not clear production caches' if Rails.env.production?
        @stores.each_value { |s| s.cleanup(*args) }
      end

      def clear(*args)
        raise 'Do not clear production caches' if Rails.env.production?
        @stores.each_value { |s| s.clear(*args) }
      end

      def read_multi(*names)
        result = {}
        @stores.each do |_name,store|
          data = store.read_multi(*names)
          result.merge! data
          names -= data.keys
        end
        result
      end

      protected

      def read_entry(key, options)
        stores = selected_stores(options)
        stores.each do |store|
          entry = store.send :read_entry, key, options
          return entry if entry.present?
        end

        return
      end

      def write_entry(key, entry, options)
        stores = selected_stores(options)
        stores.each do |store|
          result = store.send(:write_entry, key, entry, options)
          return false unless result
        end
      end

      def delete_entry(key, options)
        stores = selected_stores(options)
        stores.map { |store| store.send(:delete_entry, key, options) }.all?
      end

      private

      def selected_stores(options)
        return @stores.values if options[:all]

        only = options[:only] || :default_store
        Array.wrap(@stores[only])
      end
    end
  end
end
