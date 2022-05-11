class BustCacheBaseWorker
  include Sidekiq::Job

  sidekiq_options queue: :high_priority, retry: 15, lock: :until_executing
end
