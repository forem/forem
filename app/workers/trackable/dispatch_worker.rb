module Trackable
  # Fans a tracked event out to a single registered adapter.
  # The Trackable concern enqueues one of these per active adapter on each event.
  class DispatchWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    # A dead-lettered event is silent DEV -> Core drift: the event is gone
    # and nothing downstream will notice. Page instead of dropping quietly.
    sidekiq_retries_exhausted do |job, exception|
      Honeybadger.notify(
        exception,
        context: { adapter: job["args"]&.first, event: job["args"]&.second, trackable_dead_letter: true },
      )
    end

    def perform(adapter_name, event_name, user_ids, properties, timestamp_iso)
      adapter = Trackable::Registry.instance_for(adapter_name)
      return if adapter.nil? || !adapter.enabled?

      timestamp = timestamp_iso ? Time.iso8601(timestamp_iso) : nil

      adapter.track(
        event_name: event_name,
        user_ids: user_ids,
        properties: properties,
        timestamp: timestamp,
      )
    rescue StandardError => e
      Rails.logger.error(
        "[Trackable::DispatchWorker] adapter=#{adapter_name} event=#{event_name} error=#{e.class}: #{e.message}",
      )
      raise
    end
  end
end
