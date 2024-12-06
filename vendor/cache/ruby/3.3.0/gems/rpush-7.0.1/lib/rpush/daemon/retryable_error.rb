module Rpush
  class RetryableError < StandardError
    attr_reader :code, :description, :response

    def initialize(code, notification_id, description, response)
      @code = code
      @notification_id = notification_id
      @description = description
      @response = response
    end

    def to_s
      message
    end

    def message
      "Retryable error for #{@notification_id}, received error #{@code} (#{@description}) - retry after #{@response.header['retry-after']}"
    end
  end

  class RateLimitError < RetryableError; end
end
