module Trackable
  # Hands one Trackable::BatchEvent to a single registered adapter.
  class BatchDispatchWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    sidekiq_retries_exhausted do |job, exception|
      Rails.error.report(
        exception,
        context: { adapter: job["args"]&.first, event: job["args"]&.second, trackable_dead_letter: true },
      )
    end

    def perform(adapter_name, event_name, properties, anonymous_id, recipient_ids, timestamp_iso,
                recipient_properties = {})
      adapter = Trackable::Registry.instance_for(adapter_name)
      return if adapter.nil? || !adapter.enabled?

      adapter.track_batch(
        event_name: event_name,
        properties: properties,
        anonymous_id: anonymous_id,
        recipient_ids: recipient_ids,
        recipient_properties: recipient_properties,
        timestamp: timestamp_iso ? Time.iso8601(timestamp_iso) : nil,
      )
    rescue StandardError => e
      Rails.logger.error(
        "[Trackable::BatchDispatchWorker] adapter=#{adapter_name} event=#{event_name} error=#{e.class}: #{e.message}",
      )
      raise
    end
  end
end
