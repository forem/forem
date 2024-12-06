module Algolia
  class UpdateApiKeyResponse < BaseResponse
    include Helpers
    attr_reader :raw_response

    # @param client [Search::Client] Algolia Search Client used for verification
    # @param response [Hash] Raw response from the client
    # @param request_options [Hash] request_options used to find the api key
    #
    def initialize(client, response, request_options)
      @client          = client
      @raw_response    = response
      @request_options = request_options
      @done            = false
    end

    # Wait for the task to complete
    #
    # @param opts [Hash] contains extra parameters to send with your query
    #
    def wait(opts = {})
      retries_count = 1

      until @done
        begin
          api_key = @client.get_api_key(@raw_response[:key], opts)
          @done   = hash_includes_subset?(api_key, @request_options)
        rescue AlgoliaError => e
          raise e unless e.code == 404
          retries_count    += 1
          time_before_retry = retries_count * Defaults::WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY
          sleep(time_before_retry.to_f / 1000)
        end
      end

      self
    end
  end
end
