module StripeMock
  class ServerTimeoutError < StripeMockError

    attr_reader :associated_error

    def initialize(associated_error)
      @associated_error = associated_error
      super("Unable to connect to stripe mock server (did you forget to run `$ stripe-mock-server`?)")
    end

  end
end
