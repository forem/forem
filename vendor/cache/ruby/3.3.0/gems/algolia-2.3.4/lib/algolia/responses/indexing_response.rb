module Algolia
  class IndexingResponse < BaseResponse
    attr_reader :raw_response

    # @param index [Search::Index] Algolia Search Index used for verification
    # @param response [Hash] Raw response from the client
    #
    def initialize(index, response)
      @index        = index
      @raw_response = response
      @done         = false
    end

    # Wait for the task to complete
    #
    # @param opts [Hash] contains extra parameters to send with your query
    #
    def wait(opts = {})
      unless @done
        task_id = get_option(@raw_response, 'taskID')
        @index.wait_task(task_id, Defaults::WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY, opts)
      end

      @done = true
      self
    end
  end
end
