module Sidekiq
  class TransactionSafeRescue
    # These are common exceptions that indicate a state issue (like a race condition
    # or bad data) rather than a code issue. They are the most likely candidates
    # to poison a transaction if not handled.
    RESCUABLE_EXCEPTIONS = [
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotUnique,
      ActiveRecord::InvalidForeignKey
    ].freeze

    def call(worker, job, queue)
      yield
    rescue *RESCUABLE_EXCEPTIONS => e
      # When one of the rescuable exceptions is raised:
      # 1. Log the original error with context so it's not hidden.
      # 2. Stop the job gracefully by returning. Do not re-raise the exception.
      #
      # Re-raising would cause the job to enter Sidekiq's retry logic,
      # but the unhandled exception could still poison the transaction during
      # Sidekiq's own cleanup, leading back to the original problem.
      # This middleware PREVENTS the job from being marked as "failed".
      Sidekiq.logger.warn(
        "SIDEKIQ MIDDLEWARE: Rescued a #{e.class.name} in #{worker.class.name} (Job ID: #{job['jid']}). " \
        "Halting job to prevent transaction failure. " \
        "ERROR: #{e.message}"
      )
      # We return instead of re-raising. This tells Sidekiq the job is "done"
      # and prevents the poison/retry/fail cycle.
    end
  end
end
