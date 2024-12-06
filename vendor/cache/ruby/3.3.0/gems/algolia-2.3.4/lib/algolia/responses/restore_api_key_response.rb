module Algolia
  class RestoreApiKeyResponse < BaseResponse
    # @param index [Search::Index] Algolia Search Index used for verification
    # @param key [String] the key to check
    #
    def initialize(client, key)
      @client = client
      @key    = key
      @done   = false
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
          @done = true
        rescue AlgoliaError => e
          if e.code != 404
            raise e
          end
          retries_count    += 1
          time_before_retry = retries_count * Defaults::WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY
          sleep(time_before_retry.to_f / 1000)
        end
      end

      self
    end
  end
end
