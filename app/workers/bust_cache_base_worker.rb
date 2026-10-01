class BustCacheBaseWorker
  include Sidekiq::Job

  # For busts enqueued inside the transaction that deletes the records: the
  # push happening before commit means a failed push rolls the delete back,
  # and the delay keeps the bust from running before the delete is committed.
  AFTER_COMMIT_DELAY = 10.seconds

  sidekiq_options queue: :high_priority, retry: 15, lock: :until_executing
end
