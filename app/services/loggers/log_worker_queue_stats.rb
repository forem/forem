module Loggers
  class LogWorkerQueueStats
    class << self
      def call
        queues = Sidekiq::Queue.all.map(&:itself)
        record_totals(queues)
        record_queue_stats(queues)
      end

      private

      def record_totals(queues)
        log_to_datadog("sidekiq.queues.total_size", queues.sum(&:size))
        log_to_datadog("sidekiq.queues.total_workers", Sidekiq::Workers.new.size)
      end

      def record_queue_stats(queues)
        queue_hash = queues.map do |queue|
          [queue.name, { size: queue.size, latency: queue.latency }]
        end.to_h
        queue_hash.each do |queue_name, queue_values|
          latency = queue_values.fetch(:latency, 0)
          size = queue_values.fetch(:size, 0)
          log_to_datadog("sidekiq.queues.latency", latency, ["sidekiq_queue:#{queue_name}"])
          log_to_datadog("sidekiq.queues.size", size, ["sidekiq_queue:#{queue_name}"])
        end
      end

      def log_to_datadog(metric_name, value, tags = [])
        DatadogStatsClient.gauge(metric_name, value, tags: tags)
      end
    end
  end
end
