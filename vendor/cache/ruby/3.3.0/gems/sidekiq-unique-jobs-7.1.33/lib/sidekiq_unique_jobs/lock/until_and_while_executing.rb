# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs while the job is executing in the server process
    # - Locks on perform_in or perform_async (see {UntilExecuting})
    # - Unlocks before yielding to the worker's perform method (see {UntilExecuting})
    # - Locks before yielding to the worker's perform method (see {WhileExecuting})
    # - Unlocks after yielding to the worker's perform method (see {WhileExecuting})
    #
    # See {#lock} for more information about the client.
    # See {#execute} for more information about the server
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class UntilAndWhileExecuting < BaseLock
      #
      # Locks a sidekiq job
      #
      # @note Will call a conflict strategy if lock can't be achieved.
      #
      # @return [String, nil] the locked jid when properly locked, else nil.
      #
      # @yield to the caller when given a block
      #
      def lock(origin: :client, &block)
        unless (token = locksmith.lock)
          reflect(:lock_failed, item)
          call_strategy(origin: origin, &block)

          return
        end

        yield if block

        token
      end

      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        if locksmith.unlock
          # ensure_relocked do
          runtime_lock.execute { return yield }
          # end
        else
          reflect(:unlock_failed, item)
        end
      rescue Exception # rubocop:disable Lint/RescueException
        reflect(:execution_failed, item)
        locksmith.lock(wait: 2)

        raise
      end

      private

      def ensure_relocked
        yield
      rescue Exception # rubocop:disable Lint/RescueException
        reflect(:execution_failed, item)
        locksmith.lock

        raise
      end

      def runtime_lock
        @runtime_lock ||= SidekiqUniqueJobs::Lock::WhileExecuting.new(item.dup, callback, redis_pool)
      end
    end
  end
end
