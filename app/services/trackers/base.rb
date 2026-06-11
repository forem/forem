module Trackers
  # Base class for all Trackable adapters. Subclasses must implement #track.
  # Adapters that need credentials should override #enabled? — when false,
  # Trackable::DispatchWorker skips the adapter entirely.
  class Base
    def track(event_name:, user_ids:, properties:, timestamp: nil)
      raise NotImplementedError, "#{self.class.name} must implement #track"
    end

    def enabled?
      true
    end
  end
end
