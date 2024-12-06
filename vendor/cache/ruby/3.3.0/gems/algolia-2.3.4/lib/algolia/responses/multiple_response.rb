module Algolia
  class MultipleResponse < BaseResponse
    include Enumerable

    # @param responses [nil|Array] array of raw responses, when provided
    #
    def initialize(responses = nil)
      @raw_responses = responses || []
    end

    # Fetch the last element of the responses
    #
    def last
      @raw_responses[@raw_responses.length - 1]
    end

    # Add a new response to responses
    #
    def push(response)
      @raw_responses.push(response)
    end

    # Wait for the task to complete
    #
    # @param opts [Hash] contains extra parameters to send with your query
    #
    def wait(opts = {})
      @raw_responses.each do |response|
        response.wait(opts)
      end

      @raw_responses = []

      self
    end

    # Iterates through the responses
    #
    def each
      @raw_responses.each do |response|
        yield response
      end
    end
  end
end
