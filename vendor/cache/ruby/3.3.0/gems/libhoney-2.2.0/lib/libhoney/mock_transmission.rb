module Libhoney
  # For testing use: a mock version of TransmissionClient that retains all
  # events in an in-memory queue for inspection (and does not send them to
  # Honeycomb, or perform any network activity).
  #
  # @note This class is intended for use in tests, for example if you want to
  #       verify what events your instrumented code is sending. Use in
  #       production is not recommended.
  class MockTransmissionClient
    def initialize(**_)
      reset
    end

    # @return [Array<Event>] the recorded events
    attr_reader :events

    # Records an event
    def add(event)
      @events.push(event)
    end

    # Does nothing.
    def close(drain); end

    # Discards the recorded events
    def reset
      @events = []
    end
  end
end
