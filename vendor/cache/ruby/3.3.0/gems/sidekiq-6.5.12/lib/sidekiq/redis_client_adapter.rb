# frozen_string_literal: true

require "connection_pool"
require "redis_client"
require "redis_client/decorator"
require "uri"

module Sidekiq
  class RedisClientAdapter
    BaseError = RedisClient::Error
    CommandError = RedisClient::CommandError

    module CompatMethods
      def info
        @client.call("INFO") { |i| i.lines(chomp: true).map { |l| l.split(":", 2) }.select { |l| l.size == 2 }.to_h }
      end

      def evalsha(sha, keys, argv)
        @client.call("EVALSHA", sha, keys.size, *keys, *argv)
      end

      def brpoplpush(*args)
        @client.blocking_call(false, "BRPOPLPUSH", *args)
      end

      def brpop(*args)
        @client.blocking_call(false, "BRPOP", *args)
      end

      def set(*args)
        @client.call("SET", *args) { |r| r == "OK" }
      end
      ruby2_keywords :set if respond_to?(:ruby2_keywords, true)

      def sismember(*args)
        @client.call("SISMEMBER", *args) { |c| c > 0 }
      end

      def exists?(key)
        @client.call("EXISTS", key) { |c| c > 0 }
      end

      private

      def method_missing(*args, &block)
        @client.call(*args, *block)
      end
      ruby2_keywords :method_missing if respond_to?(:ruby2_keywords, true)

      def respond_to_missing?(name, include_private = false)
        super # Appease the linter. We can't tell what is a valid command.
      end
    end

    CompatClient = RedisClient::Decorator.create(CompatMethods)

    class CompatClient
      %i[scan sscan zscan hscan].each do |method|
        alias_method :"#{method}_each", method
        undef_method method
      end

      def disconnect!
        @client.close
      end

      def connection
        {id: @client.id}
      end

      def redis
        self
      end

      def _client
        @client
      end

      def message
        yield nil, @queue.pop
      end

      # NB: this method does not return
      def subscribe(chan)
        @queue = ::Queue.new

        pubsub = @client.pubsub
        pubsub.call("subscribe", chan)

        loop do
          evt = pubsub.next_event
          next if evt.nil?
          next unless evt[0] == "message" && evt[1] == chan

          (_, _, msg) = evt
          @queue << msg
          yield self
        end
      end
    end

    def initialize(options)
      opts = client_opts(options)
      @config = if opts.key?(:sentinels)
        RedisClient.sentinel(**opts)
      else
        RedisClient.config(**opts)
      end
    end

    def new_client
      CompatClient.new(@config.new_client)
    end

    private

    def client_opts(options)
      opts = options.dup

      if opts[:namespace]
        Sidekiq.logger.error("Your Redis configuration uses the namespace '#{opts[:namespace]}' but this feature isn't supported by redis-client. " \
          "Either use the redis adapter or remove the namespace.")
        Kernel.exit(-127)
      end

      opts.delete(:size)
      opts.delete(:pool_timeout)

      if opts[:network_timeout]
        opts[:timeout] = opts[:network_timeout]
        opts.delete(:network_timeout)
      end

      if opts[:driver]
        opts[:driver] = opts[:driver].to_sym
      end

      opts[:name] = opts.delete(:master_name) if opts.key?(:master_name)
      opts[:role] = opts[:role].to_sym if opts.key?(:role)
      opts.delete(:url) if opts.key?(:sentinels)

      # Issue #3303, redis-rb will silently retry an operation.
      # This can lead to duplicate jobs if Sidekiq::Client's LPUSH
      # is performed twice but I believe this is much, much rarer
      # than the reconnect silently fixing a problem; we keep it
      # on by default.
      opts[:reconnect_attempts] ||= 1

      opts
    end
  end
end

Sidekiq::RedisConnection.adapter = Sidekiq::RedisClientAdapter
