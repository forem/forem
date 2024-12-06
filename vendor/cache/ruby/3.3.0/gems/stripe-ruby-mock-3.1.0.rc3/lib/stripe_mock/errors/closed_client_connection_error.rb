module StripeMock
  class ClosedClientConnectionError < StripeMockError

    def initialize
      super("This StripeMock client has already been closed.")
    end

  end
end
