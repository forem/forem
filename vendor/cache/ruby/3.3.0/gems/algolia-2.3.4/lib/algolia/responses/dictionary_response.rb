module Algolia
  class DictionaryResponse < BaseResponse
    include CallType

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
    def wait(_opts = {})
      until @done
        res    = @client.custom_request({}, path_encode('/1/task/%s', @raw_response[:taskID]), :GET, READ)
        status = get_option(res, 'status')
        if status == 'published'
          @done = true
        end
        sleep(Defaults::WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY / 1000)
      end

      self
    end
  end
end
