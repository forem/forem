require 'redis'
require 'redis/store/factory'
require 'redis/distributed_store'
require 'redis/store/namespace'
require 'redis/store/serialization'
require 'redis/store/version'
require 'redis/store/redis_version'
require 'redis/store/ttl'
require 'redis/store/interface'
require 'redis/store/redis_version'

class Redis
  class Store < self
    include Ttl, Interface, RedisVersion

    def initialize(options = {})
      orig_options = options.dup

      _remove_unsupported_options(options)
      # The options here is updated
      super(options)

      unless orig_options[:marshalling].nil?
        puts %(
          DEPRECATED: You are passing the :marshalling option, which has been
          replaced with `serializer: Marshal` to support pluggable serialization
          backends. To disable serialization (much like disabling marshalling),
          pass `serializer: nil` in your configuration.

          The :marshalling option will be removed for redis-store 2.0.
        )
      end

      @serializer = orig_options.key?(:serializer) ? orig_options.delete(:serializer) : Marshal

      unless orig_options[:marshalling].nil?
        # `marshalling` only used here, might not be supported in `super`
        @serializer = orig_options.delete(:marshalling) ? Marshal : nil
      end

      _extend_marshalling
      _extend_namespace orig_options
    end

    def reconnect
      @client.reconnect
    end

    def to_s
      "Redis Client connected to #{location} against DB #{@client.db}"
    end

    def location
      if @client.path
        @client.path
      else
        h = @client.host
        h = "[#{h}]" if h.include?(":")
        "#{h}:#{@client.port}"
      end
    end

    private
      def _remove_unsupported_options(options)
        return unless self.class.redis_client_defined?

        # Unsupported keywords should be removed to avoid errors
        # https://github.com/redis-rb/redis-client/blob/v0.13.0/lib/redis_client/config.rb#L21
        options.delete(:raw)
        options.delete(:serializer)
        options.delete(:marshalling)
        options.delete(:namespace)
        options.delete(:scheme)
      end

      def _extend_marshalling
        extend Serialization unless @serializer.nil?
      end

      def _extend_namespace(options)
        @namespace = options[:namespace]
        extend Namespace
      end
  end
end
