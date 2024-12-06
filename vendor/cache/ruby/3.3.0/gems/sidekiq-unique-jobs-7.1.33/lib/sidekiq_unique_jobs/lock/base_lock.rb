# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Abstract base class for locks
    #
    # @abstract
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class BaseLock
      extend Forwardable

      # includes "SidekiqUniqueJobs::Logging"
      # @!parse include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::Logging

      # includes "SidekiqUniqueJobs::Reflectable"
      # @!parse include SidekiqUniqueJobs::Reflectable
      include SidekiqUniqueJobs::Reflectable

      #
      # Validates that the sidekiq_options for the worker is valid
      #
      # @param [Hash] options the sidekiq_options given to the worker
      #
      # @return [void]
      #
      def self.validate_options(options = {})
        Validator.validate(options)
      end

      # NOTE: Mainly used for a clean testing API
      #
      def_delegators :locksmith, :locked?

      # @param [Hash] item the Sidekiq job hash
      # @param [Proc] callback the callback to use after unlock
      # @param [Sidekiq::RedisConnection, ConnectionPool] redis_pool the redis connection
      def initialize(item, callback, redis_pool = nil)
        @item       = item
        @callback   = callback
        @redis_pool = redis_pool
        @attempt    = 0
        prepare_item # Used to ease testing
        @lock_config = LockConfig.new(item)
      end

      #
      # Locks a sidekiq job
      #
      # @note Will call a conflict strategy if lock can't be achieved.
      #
      # @return [String, nil] the locked jid when properly locked, else nil.
      #
      # @yield to the caller when given a block
      #
      def lock
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      # Execute the job in the Sidekiq server processor
      # @raise [NotImplementedError] needs to be implemented in child class
      def execute
        raise NotImplementedError, "##{__method__} needs to be implemented in #{self.class}"
      end

      #
      # The lock manager/client
      #
      # @api private
      # @return [SidekiqUniqueJobs::Locksmith] the locksmith for this sidekiq job
      #
      def locksmith
        @locksmith ||= SidekiqUniqueJobs::Locksmith.new(item, redis_pool)
      end

      private

      # @!attribute [r] item
      #   @return [Hash<String, Object>] the Sidekiq job hash
      attr_reader :item
      # @!attribute [r] lock_config
      #   @return [LockConfig] a lock configuration
      attr_reader :lock_config
      # @!attribute [r] redis_pool
      #   @return [Sidekiq::RedisConnection, ConnectionPool, NilClass] the redis connection
      attr_reader :redis_pool
      # @!attribute [r] callback
      #   @return [Proc] the block to call after unlock
      attr_reader :callback
      # @!attribute [r] attempt
      #   @return [Integer] the current locking attempt
      attr_reader :attempt

      #
      # Eases testing by allowing the lock implementation to add the missing
      # keys to the job hash.
      #
      #
      # @return [void] the return value should be irrelevant
      #
      def prepare_item
        return if item.key?(LOCK_DIGEST)

        # The below should only be done to ease testing
        # in production this will be done by the middleware
        SidekiqUniqueJobs::Job.prepare(item)
      end

      #
      # Call whatever strategry that has been configured
      #
      # @param [Symbol] origin: the origin `:client` or `:server`
      #
      # @return [void] the return value is irrelevant
      #
      # @yieldparam [void] if a new job id was set and a block is given
      # @yieldreturn [void] the yield is irrelevant, it only provides a mechanism in
      #   one specific situation to yield back to the middleware.
      def call_strategy(origin:)
        new_job_id = nil
        strategy   = strategy_for(origin)
        @attempt  += 1

        strategy.call { new_job_id = lock if strategy.replace? && @attempt < 2 }
        yield if new_job_id && block_given?
      end

      def unlock_and_callback
        return callback_safely if locksmith.unlock

        reflect(:unlock_failed, item)
      end

      def callback_safely
        callback&.call
        item[JID]
      rescue StandardError
        reflect(:after_unlock_callback_failed, item)
        raise
      end

      def strategy_for(origin)
        case origin
        when :client
          client_strategy
        when :server
          server_strategy
        else
          raise SidekiqUniqueJobs::InvalidArgument,
                "#origin needs to be either `:server` or `:client`"
        end
      end

      def client_strategy
        @client_strategy ||=
          OnConflict.find_strategy(lock_config.on_client_conflict).new(item, redis_pool)
      end

      def server_strategy
        @server_strategy ||=
          OnConflict.find_strategy(lock_config.on_server_conflict).new(item, redis_pool)
      end
    end
  end
end
