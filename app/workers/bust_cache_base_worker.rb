class BustCacheBaseWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high_priority, retry: 15, lock: :until_executing
end
