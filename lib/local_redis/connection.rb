require "redis-client"
require "redis"

module LocalRedis
  # Dedicated disposable-cache connections bypass global command instrumentation.
  # Hosted Redis clients retain their normal tracing and middleware.
  class Connection
    module DirectCommands
      def call(_command, _config)
        yield
      end

      def call_pipelined(_commands, _config)
        yield
      end
    end

    def initialize(url)
      @client = RedisClient.config(url: url, timeout: 0.05, reconnect_attempts: false,
                                   middlewares: [DirectCommands]).new_client
    end

    def eval(script, keys:, argv: [])
      command("EVAL", script, keys.size, *keys, *argv)
    end

    def flushdb(async:)
      command("FLUSHDB", async ? "ASYNC" : "SYNC")
    end

    def del(key)
      command("DEL", key)
    end

    def close
      @client.close
    end

    private

    def command(*args)
      @client.call(*args)
    rescue RedisClient::Error => e
      # Retain the local tier's existing optional-cache failure contract.
      raise Redis::BaseError, e.message
    end
  end
end
