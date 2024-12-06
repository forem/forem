# frozen_string_literal: true

class Redis
  module Commands
    module Transactions
      # Mark the start of a transaction block.
      #
      # Passing a block is optional.
      #
      # @example With a block
      #   redis.multi do |multi|
      #     multi.set("key", "value")
      #     multi.incr("counter")
      #   end # => ["OK", 6]
      #
      # @example Without a block
      #   redis.multi
      #     # => "OK"
      #   redis.set("key", "value")
      #     # => "QUEUED"
      #   redis.incr("counter")
      #     # => "QUEUED"
      #   redis.exec
      #     # => ["OK", 6]
      #
      # @yield [multi] the commands that are called inside this block are cached
      #   and written to the server upon returning from it
      # @yieldparam [Redis] multi `self`
      #
      # @return [String, Array<...>]
      #   - when a block is not given, `OK`
      #   - when a block is given, an array with replies
      #
      # @see #watch
      # @see #unwatch
      def multi(&block) # :nodoc:
        if block_given?
          if block&.arity == 0
            Pipeline.deprecation_warning("multi", Kernel.caller_locations(1, 5))
          end

          synchronize do |prior_client|
            pipeline = Pipeline::Multi.new(prior_client)
            pipelined_connection = PipelinedConnection.new(pipeline)
            yield pipelined_connection
            prior_client.call_pipeline(pipeline)
          end
        else
          send_command([:multi])
        end
      end

      # Watch the given keys to determine execution of the MULTI/EXEC block.
      #
      # Using a block is optional, but is necessary for thread-safety.
      #
      # An `#unwatch` is automatically issued if an exception is raised within the
      # block that is a subclass of StandardError and is not a ConnectionError.
      #
      # @example With a block
      #   redis.watch("key") do
      #     if redis.get("key") == "some value"
      #       redis.multi do |multi|
      #         multi.set("key", "other value")
      #         multi.incr("counter")
      #       end
      #     else
      #       redis.unwatch
      #     end
      #   end
      #     # => ["OK", 6]
      #
      # @example Without a block
      #   redis.watch("key")
      #     # => "OK"
      #
      # @param [String, Array<String>] keys one or more keys to watch
      # @return [Object] if using a block, returns the return value of the block
      # @return [String] if not using a block, returns `OK`
      #
      # @see #unwatch
      # @see #multi
      def watch(*keys)
        synchronize do |client|
          res = client.call([:watch, *keys])

          if block_given?
            begin
              yield(self)
            rescue ConnectionError
              raise
            rescue StandardError
              unwatch
              raise
            end
          else
            res
          end
        end
      end

      # Forget about all watched keys.
      #
      # @return [String] `OK`
      #
      # @see #watch
      # @see #multi
      def unwatch
        send_command([:unwatch])
      end

      # Execute all commands issued after MULTI.
      #
      # Only call this method when `#multi` was called **without** a block.
      #
      # @return [nil, Array<...>]
      #   - when commands were not executed, `nil`
      #   - when commands were executed, an array with their replies
      #
      # @see #multi
      # @see #discard
      def exec
        send_command([:exec])
      end

      # Discard all commands issued after MULTI.
      #
      # Only call this method when `#multi` was called **without** a block.
      #
      # @return [String] `"OK"`
      #
      # @see #multi
      # @see #exec
      def discard
        send_command([:discard])
      end
    end
  end
end
