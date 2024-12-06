module StripeMock
  class StripeMockError < StandardError

    attr_reader :message

    def initialize(message)
      @message = message
    end

    def to_s
      @message
    end

  end
end
