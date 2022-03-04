module Metrics
  class RecordBackgroundQueueStatsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :high_priority, retry: 10

    def perform
      Loggers::LogWorkerQueueStats.call
    end
  end
end
