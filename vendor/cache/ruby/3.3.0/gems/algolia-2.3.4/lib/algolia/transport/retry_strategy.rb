module Algolia
  module Transport
    # Class RetryStatregy
    class RetryStrategy
      include RetryOutcomeType

      # @param config [Search::Config] config which contains the hosts
      #
      def initialize(config)
        @hosts = config.default_hosts
        @lock  = Mutex.new
      end

      # Retrieves the tryable hosts
      #
      # @param call_type [binary] type of the host
      #
      # @return [Array] list of StatefulHost
      #
      def get_tryable_hosts(call_type)
        @lock.synchronize do
          reset_expired_hosts

          if @hosts.any? { |host| host.up && flag?(host.accept, call_type) }
            @hosts.select { |host| host.up && flag?(host.accept, call_type) }
          else
            @hosts.each do |host|
              reset(host) if flag?(host.accept, call_type)
            end
            @hosts
          end
        end
      end

      # Decides on the outcome of the request
      #
      # @param tryable_host [StatefulHost] host to test against
      # @param http_response_code [Integer] http response code
      # @param is_timed_out [Boolean] whether or not the request timed out
      #
      # @return [Binary] retry outcome code
      #
      def decide(tryable_host, http_response_code: nil, is_timed_out: false, network_failure: false)
        @lock.synchronize do
          if !is_timed_out && success?(http_response_code)
            tryable_host.up       = true
            tryable_host.last_use = Time.now.utc
            SUCCESS
          elsif !is_timed_out && retryable?(http_response_code, network_failure)
            tryable_host.up       = false
            tryable_host.last_use = Time.now.utc
            RETRY
          elsif is_timed_out
            tryable_host.up           = true
            tryable_host.last_use     = Time.now.utc
            tryable_host.retry_count += 1
            RETRY
          else
            FAILURE
          end
        end
      end

      private

      # @param http_response_code [Integer]
      #
      # @return [Boolean]
      #
      def success?(http_response_code)
        !http_response_code.nil? && (http_response_code.to_i / 100).floor == 2
      end

      # @param http_response_code [Integer]
      #
      # @return [Boolean]
      #
      def retryable?(http_response_code, network_failure)
        if network_failure
          return true
        end

        !http_response_code.nil? && (http_response_code.to_i / 100).floor != 2 && (http_response_code.to_i / 100).floor != 4
      end

      # Iterates in the hosts list and reset the ones that are down
      #
      def reset_expired_hosts
        @hosts.each do |host|
          host_last_usage = Time.now.utc - host.last_use
          reset(host) if !host.up && host_last_usage.to_i > Defaults::TTL
        end
      end

      # Reset a single host
      #
      # @param host [StatefulHost]
      #
      def reset(host)
        host.up          = true
        host.retry_count = 0
        host.last_use    = Time.now.utc
      end

      # Make a binary check to know whether the item contains the flag
      #
      # @param item [binary] item to check
      # @param flag [binary] flag to find in the item
      #
      # @return [Boolean]
      #
      def flag?(item, flag)
        (item & (1 << (flag - 1))) > 0
      end
    end
  end
end
