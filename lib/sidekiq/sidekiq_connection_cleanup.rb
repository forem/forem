module Sidekiq
  # Define the class directly under Sidekiq to match the file path
  # lib/sidekiq/sidekiq_connection_cleanup.rb
  class SidekiqConnectionCleanup
    def call(worker, msg, queue)
      yield
    ensure
      conn = ActiveRecord::Base.connection

      # If there is an active (or aborted) transaction, roll it back first.
      # `open_transactions` > 0 means some transaction was started and never closed.
      if conn.open_transactions.positive?
        begin
          conn.rollback_db_transaction
        rescue StandardError => e
          # If rollback itself fails (rare), log and continue clearing connections
          Rails.logger.warn "Sidekiq ConnectionCleanup: rollback failed: #{e.class}: #{e.message}"
        end
      end

      # Now clear the connection so it's returned to the pool cleanly
      ActiveRecord::Base.clear_active_connections!
    end
  end
end
