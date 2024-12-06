module Algolia
  class DeleteApiKeyResponse < BaseResponse
    attr_reader :raw_response

    # @param client [Search::Client] Algolia Search Client used for verification
    # @param response [Hash] Raw response from the client
    # @param key [String] the key to check
    #
    def initialize(client, response, key)
      @client       = client
      @raw_response = response
      @key          = key
      @done         = false
    end

    # Wait for the task to complete
    #
    # @param opts [Hash] contains extra parameters to send with your query
    #
    def wait(opts = {})
      retries_count = 1

      until @done
        begin
          @client.get_api_key(@key, opts)
        rescue AlgoliaError => e
          @done = e.code == 404

          unless @done
            retries_count    += 1
            time_before_retry = retries_count * Defaults::WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY
            sleep(time_before_retry.to_f / 1000)
          end
        end
      end

      self
    end
  end
end
