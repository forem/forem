class LogWorkerQueueStats
  def self.perform
    record_totals
    record_queue_stats
  end

  private

  def self.record_totals
    log_to_datadog("sidekiq.queues.total_size", Sidekiq::Queue.all.map(&:size).sum)
    log_to_datadog("sidekiq.queues.total_workers", Sidekiq::Workers.new.size)
  end
  private_class_method :record_totals

  def self.record_queue_stats
    queues = Sidekiq::Queue.all.map { |queue| [queue.name, size: queue.size, latency: queue.latency] }.to_h
    queues.each do |queue_name, queue_values|
      latency = queue_values.fetch(:latency, 0)
      size = queue_values.fetch(:size, 0)
      log_to_datadog("sidekiq.queues.latency", latency, ["sidekiq_queue:#{queue_name}"])
      log_to_datadog("sidekiq.queues.size", size, ["sidekiq_queue:#{queue_name}"])
    end
  end
  private_class_method :record_queue_stats

  def self.log_to_datadog(metric_name, value, tags = [])
    DataDogStatsClient.gauge(metric_name, value, tags: tags)
  end
  private_class_method :log_to_datadog
end
