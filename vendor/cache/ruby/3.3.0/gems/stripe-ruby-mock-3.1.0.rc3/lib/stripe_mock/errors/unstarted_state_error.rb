module StripeMock
  class UnstartedStateError < StripeMockError

    def initialize
      super("StripeMock has not been started. Please call StripeMock.start or StripeMock.start_client")
    end

  end
end
