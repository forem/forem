# frozen_string_literal: true

require 'json'
require 'logger'
require 'faraday/http_cache/memory_store'

module Faraday
  class HttpCache < Faraday::Middleware
    module Strategies
      # Base class for all strategies.
      # @abstract
      #
      # @example
      #
      #   # Creates a new strategy using a MemCached backend from ActiveSupport.
      #   mem_cache_store = ActiveSupport::Cache.lookup_store(:mem_cache_store, ['localhost:11211'])
      #   Faraday::HttpCache::Strategies::ByVary.new(store: mem_cache_store)
      #
      #   # Reuse some other instance of an ActiveSupport::Cache::Store object.
      #   Faraday::HttpCache::Strategies::ByVary.new(store: Rails.cache)
      #
      #   # Creates a new strategy using Marshal for serialization.
      #   Faraday::HttpCache::Strategies::ByVary.new(store: Rails.cache, serializer: Marshal)
      class BaseStrategy
        # Returns the underlying cache store object.
        attr_reader :cache

        # @param [Hash] options the options to create a message with.
        # @option options [Faraday::HttpCache::MemoryStore, nil] :store - a cache
        #   store object that should respond to 'read', 'write', and 'delete'.
        # @option options [#dump#load] :serializer - an object that should
        #   respond to 'dump' and 'load'.
        # @option options [Logger, nil] :logger - an object to be used to emit warnings.
        def initialize(options = {})
          @cache = options[:store] || Faraday::HttpCache::MemoryStore.new
          @serializer = options[:serializer] || JSON
          @logger = options[:logger] || Logger.new(IO::NULL)
          @cache_salt = (@serializer.is_a?(Module) ? @serializer : @serializer.class).name
          assert_valid_store!
        end

        # Store a response inside the cache.
        # @abstract
        def write(_request, _response)
          raise NotImplementedError, 'Implement this method in your strategy'
        end

        # Read a response from the cache.
        # @abstract
        def read(_request)
          raise NotImplementedError, 'Implement this method in your strategy'
        end

        # Delete responses from the cache by the url.
        # @abstract
        def delete(_url)
          raise NotImplementedError, 'Implement this method in your strategy'
        end

        private

        # @private
        # @raise [ArgumentError] if the cache object doesn't support the expect API.
        def assert_valid_store!
          unless cache.respond_to?(:read) && cache.respond_to?(:write) && cache.respond_to?(:delete)
            raise ArgumentError.new("#{cache.inspect} is not a valid cache store as it does not responds to 'read', 'write' or 'delete'.")
          end
        end

        def serialize_entry(*objects)
          objects.map { |object| serialize_object(object) }
        end

        def serialize_object(object)
          @serializer.dump(object)
        end

        def deserialize_entry(*objects)
          objects.map { |object| deserialize_object(object) }
        end

        def deserialize_object(object)
          @serializer.load(object).each_with_object({}) do |(key, value), hash|
            hash[key.to_sym] = value
          end
        end

        def warn(message)
          @logger.warn(message)
        end
      end
    end
  end
end
