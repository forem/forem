module Algolia
  class MultipleIndexBatchIndexingResponse < BaseResponse
    attr_reader :raw_response

    # @param client [Search::Client] Algolia Search Client used for verification
    # @param response [Hash] Raw response from the client
    #
    def initialize(client, response)
      @client       = client
      @raw_response = response
      @done         = false
    end

    # Wait for the task to complete
    #
    # @param opts [Hash] contains extra parameters to send with your query
    #
    def wait(opts = {})
      unless @done
        @raw_response[:taskID].each do |index_name, task_id|
          @client.wait_task(index_name, task_id, Defaults::WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY, opts)
        end
      end

      @done = true
      self
    end
  end
end
