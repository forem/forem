require "active_support/cache"
require "active_support/version"

# This class is modeled off of https://github.com/mezis/level2 and is temporary
#
# Any cache statement as-is will use :default_store (Memcache)
# Any cache statement with the option only: :redis will only use Redis
# Any cache statement with the option all: true will write to Redis and Memcache BUT will read/return the value read from Memcache.

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
        raise "Do not clear production caches" if Rails.env.production?

        @stores.each_value { |s| s.cleanup(*args) }
      end

      def clear(*args)
        raise "Do not clear production caches" if Rails.env.production?

        @stores.each_value { |s| s.clear(*args) }
      end

      def read_multi(*names)
        result = {}
        @stores.each do |_name, store|
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
          entry = if store.options[:dalli_store]
                    store.instance_variable_get(:@data).get(key, options)
                  else
                    store.send :read_entry, key, options
                  end

          return entry if entry.present?
        end

        nil
      end

      def write_entry(key, entry, options)
        stores = selected_stores(options)
        stores.each do |store|
          # Ensure default expiration gets set for keys without
          write_options = options.reverse_merge(expires_in: store.options[:expires_in])

          # Add connection to options hash for dalli_store
          write_options = write_options.merge(connection: store.instance_variable_get(:@data)) if store.options[:dalli_store]

          result = store.send(:write_entry, key, entry, write_options)
          return false unless result
        end

        "OK"
      end

      def delete_entry(key, options)
        stores = selected_stores(options)
        stores.map { |store| store.send(:delete_entry, key, options) }.all?
      end

      private

      def selected_stores(options)
        return @stores.values if options[:all]

        only = options[:only] || :default_store
        raise "Store not found!" unless @stores[only]

        Array.wrap(@stores[only])
      end
    end
  end
end
