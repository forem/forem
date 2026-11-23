module Trackers
  # Base class for all Trackable adapters. Subclasses must implement #track and
  # #track_batch. Adapters that need credentials should override #enabled? —
  # when false, the dispatch workers skip the adapter entirely.
  class Base
    def track(event_name:, user_ids:, properties:, timestamp: nil)
      raise NotImplementedError, "#{self.class.name} must implement #track"
    end

    # One event about many users (see Trackable::BatchEvent). recipient_ids is
    # nil for events that name no recipients; recipient_properties holds
    # per-recipient values aligned with it.
    def track_batch(event_name:, properties:, anonymous_id:, recipient_ids: nil, recipient_properties: {},
                    timestamp: nil)
      raise NotImplementedError, "#{self.class.name} must implement #track_batch"
    end

    # Delivers anything the adapter buffers in memory. Called on shutdown.
    def flush; end

    def enabled?
      true
    end
  end
end
