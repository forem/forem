module Trackers
  # Default adapter. Records nothing. Used as a safe default and in test/dev.
  class Null < Base
    # Signature mirrors Trackers::Base#track to document the contract for
    # subclasses; the args are intentionally unused.
    def track(event_name:, user_ids:, properties:, timestamp: nil) # rubocop:disable Lint/UnusedMethodArgument
      nil
    end
  end
end
