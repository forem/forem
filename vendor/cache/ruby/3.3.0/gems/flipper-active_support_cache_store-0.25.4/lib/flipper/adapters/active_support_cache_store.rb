require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in ActiveSupport::ActiveSupportCacheStore caches.
    #
    class ActiveSupportCacheStore
      include ::Flipper::Adapter

      Version = 'v1'.freeze
      Namespace = "flipper/#{Version}".freeze
      FeaturesKey = "#{Namespace}/features".freeze
      GetAllKey = "#{Namespace}/get_all".freeze

      # Private
      def self.key_for(key)
        "#{Namespace}/feature/#{key}"
      end

      # Internal
      attr_reader :cache

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(adapter, cache, expires_in: nil, write_through: false)
        @adapter = adapter
        @name = :active_support_cache_store
        @cache = cache
        @write_options = {}
        @write_options[:expires_in] = expires_in if expires_in
        @write_through = write_through
      end

      # Public
      def features
        read_feature_keys
      end

      # Public
      def add(feature)
        result = @adapter.add(feature)
        @cache.delete(FeaturesKey)
        result
      end

      ## Public
      def remove(feature)
        result = @adapter.remove(feature)
        @cache.delete(FeaturesKey)

        if @write_through
          @cache.write(key_for(feature.key), default_config, @write_options)
        else
          @cache.delete(key_for(feature.key))
        end

        result
      end

      ## Public
      def clear(feature)
        result = @adapter.clear(feature)
        @cache.delete(key_for(feature.key))
        result
      end

      ## Public
      def get(feature)
        @cache.fetch(key_for(feature.key), @write_options) do
          @adapter.get(feature)
        end
      end

      def get_multi(features)
        read_many_features(features)
      end

      def get_all
        if @cache.write(GetAllKey, Time.now.to_i, @write_options.merge(unless_exist: true))
          response = @adapter.get_all
          response.each do |key, value|
            @cache.write(key_for(key), value, @write_options)
          end
          @cache.write(FeaturesKey, response.keys.to_set, @write_options)
          response
        else
          features = read_feature_keys.map { |key| Flipper::Feature.new(key, self) }
          read_many_features(features)
        end
      end

      ## Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)

        if @write_through
          @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
        else
          @cache.delete(key_for(feature.key))
        end

        result
      end

      ## Public
      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)

        if @write_through
          @cache.write(key_for(feature.key), @adapter.get(feature), @write_options)
        else
          @cache.delete(key_for(feature.key))
        end

        result
      end

      private

      def key_for(key)
        self.class.key_for(key)
      end

      # Internal: Returns an array of the known feature keys.
      def read_feature_keys
        @cache.fetch(FeaturesKey, @write_options) { @adapter.features }
      end

      # Internal: Given an array of features, attempts to read through cache in
      # as few network calls as possible.
      def read_many_features(features)
        keys = features.map { |feature| key_for(feature.key) }
        cache_result = @cache.read_multi(*keys)
        uncached_features = features.reject { |feature| cache_result[key_for(feature)] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            @cache.write(key_for(key), value, @write_options)
            cache_result[key_for(key)] = value
          end
        end

        result = {}
        features.each do |feature|
          result[feature.key] = cache_result[key_for(feature.key)]
        end
        result
      end
    end
  end
end
