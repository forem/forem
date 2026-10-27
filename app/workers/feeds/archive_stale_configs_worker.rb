module Feeds
  class ArchiveStaleConfigsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5, lock: :until_executing, on_conflict: :replace

    def perform
      FeedConfig.archive_stale_configs!
    end
  end
end
