module StripeMock
  class UninitializedInstanceError < StripeMockError

    def initialize
      super("StripeMock instance is nil (did you forget to call `StripeMock.start`?)")
    end

  end
end
