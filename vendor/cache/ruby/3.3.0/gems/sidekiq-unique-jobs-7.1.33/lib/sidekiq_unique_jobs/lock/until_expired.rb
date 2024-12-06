# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # UntilExpired locks until the job expires
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class UntilExpired < UntilExecuted
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
      def execute(&block)
        executed = locksmith.execute(&block)

        reflect(:execution_failed, item) unless executed
      end
    end
  end
end
