module Trackers
  # Default adapter. Records nothing. Used as a safe default and in test/dev.
  class Null < Base
    def track(event_name:, user_ids:, properties:, timestamp: nil) # rubocop:disable Lint/UnusedMethodArgument
      nil
    end
  end
end
