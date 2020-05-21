task record_data_counts: :environment do
  Metrics::RecordDataCountsWorker.perform_async
end

task log_worker_queue_stats: :environment do
  Metrics::RecordBackgroundQueueStatsWorker.perform_async
end

task log_daily_usage_measurables: :environment do
  Metrics::RecordDailyUsageWorker.perform_async
end
