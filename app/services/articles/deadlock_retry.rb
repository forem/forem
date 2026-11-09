module Articles
  # Shared helper for retrying article persistence when concurrent tag updates
  # or foreign-key row locks raise ActiveRecord::Deadlocked.
  module DeadlockRetry
    MAX_DEADLOCK_RETRIES = 2

    private

    # Executes the given block, retrying up to MAX_DEADLOCK_RETRIES times with
    # linear backoff when ActiveRecord::Deadlocked is raised.
    def with_deadlock_retry
      attempts = 0
      begin
        yield
      rescue ActiveRecord::Deadlocked
        attempts += 1
        raise if attempts > MAX_DEADLOCK_RETRIES

        sleep(0.05 * attempts)
        retry
      end
    end
  end
end
