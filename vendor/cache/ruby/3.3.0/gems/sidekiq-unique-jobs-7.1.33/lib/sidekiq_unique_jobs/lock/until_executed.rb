# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    # Locks jobs until the server is done executing the job
    # - Locks on perform_in or perform_async
    # - Unlocks after yielding to the worker's perform method
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class UntilExecuted < BaseLock
      #
      # Locks a sidekiq job
      #
      # @note Will call a conflict strategy if lock can't be achieved.
      #
      # @return [String, nil] the locked jid when properly locked, else nil.
      #
      # @yield to the caller when given a block
      #
      def lock(&block)
        unless (token = locksmith.lock)
          reflect(:lock_failed, item)
          call_strategy(origin: :client, &block)

          return
        end

        yield if block

        token
      end

      # Executes in the Sidekiq server process
      # @yield to the worker class perform method
      def execute
        executed = locksmith.execute do
          yield
        ensure
          unlock_and_callback
        end

        reflect(:execution_failed, item) unless executed

        nil
      end
    end
  end
end
