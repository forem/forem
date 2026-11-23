module Trackable
  # Enqueues one event about many users as a single dispatch per adapter, instead
  # of the per-user fan-out the Trackable concern does. Adapters decide how the
  # recipients travel (Trackers::CustomerioCdp chunks them into one call per
  # thousand ids). recipient_properties maps a property name to per-recipient
  # values aligned with recipient_ids, which travel beside recipient_user_ids.
  # Properties must be JSON-safe with string keys for Sidekiq.strict_args!.
  module BatchEvent
    def self.enqueue(event_name, properties:, anonymous_id:, recipient_ids: nil, recipient_properties: {})
      timestamp = Time.current.iso8601(3)
      recipient_ids = recipient_ids&.map(&:to_i)

      Trackable::Registry.active_names.each do |adapter_name|
        Trackable::BatchDispatchWorker.perform_async(
          adapter_name.to_s, event_name, properties, anonymous_id, recipient_ids, timestamp, recipient_properties
        )
      end
    end
  end
end
