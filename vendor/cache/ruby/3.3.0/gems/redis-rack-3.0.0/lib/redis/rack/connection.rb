class Redis
  module Rack
    class Connection
      POOL_KEYS = %i[pool pool_size pool_timeout].freeze

      def initialize(options = {})
        @options = options
        @store = options[:redis_store]
        @pool = options[:pool]

        if @pool && !@pool.is_a?(ConnectionPool)
          raise ArgumentError, "pool must be an instance of ConnectionPool"
        end

        if @store && !@store.is_a?(Redis::Store)
          raise ArgumentError, "redis_store must be an instance of Redis::Store (currently #{@store.class.name})"
        end
      end

      def with(&block)
        if pooled?
          pool.with(&block)
        else
          block.call(store)
        end
      end

      def pooled?
        return @pooled if defined?(@pooled)

        @pooled = POOL_KEYS.any? { |key| @options.key?(key) }
      end

      def pool
        @pool ||= ConnectionPool.new(pool_options) { store } if pooled?
      end

      def store
        @store ||= Redis::Store::Factory.create(@options[:redis_server])
      end

      def pool_options
        {
          size: @options[:pool_size],
          timeout: @options[:pool_timeout]
        }.reject { |key, value| value.nil? }.to_h
      end
    end
  end
end
