module Feeds
  class ImportLogCleanupWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform
      Feeds::ImportLog.for_cleanup.in_batches(of: 1000).delete_all
    end
  end
end
