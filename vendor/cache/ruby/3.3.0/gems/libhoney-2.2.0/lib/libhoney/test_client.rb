require 'libhoney/client'
require 'libhoney/mock_transmission'

module Libhoney
  # A client with the network stubbed out for testing purposes. Does not
  # actually send any events to Honeycomb; instead, records events for later
  # inspection.
  #
  # @note This class is intended for use in tests, for example if you want to
  #       verify what events your instrumented code is sending. Use in
  #       production is not recommended.
  class TestClient < Client
    def initialize(*args, **kwargs)
      super(*args, transmission: MockTransmissionClient.new, **kwargs)
    end

    # @return [Array<Event>] the recorded events
    def events
      @transmission.events
    end

    # Discards the recorded events
    def reset
      @transmission.reset
    end
  end
end
