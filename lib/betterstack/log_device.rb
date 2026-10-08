require "logtail"

module Betterstack
  # Logtail's HTTP log device, fixed for running in every Puma worker and Sidekiq process.
  # Only loaded when BETTERSTACK_SOURCE_TOKEN is set (see config/initializers/betterstack.rb).
  #
  # The overridden methods are private in logtail; spec/lib/betterstack/log_device_spec.rb
  # fails if an upgrade renames them.
  class LogDevice < Logtail::LogDevices::HTTP
    # Upstream reconnects immediately after a failed connection, so a fast failure (refused,
    # TLS error, unknown host) keeps a CPU core busy until Better Stack is reachable again.
    RECONNECT_INTERVAL = 1 # second

    # Upstream waits up to 20 seconds for undelivered logs when the process exits. Heroku
    # sends SIGKILL 30 seconds after SIGTERM, so don't let an outage hold up shutdown.
    FLUSH_TIMEOUT = 5 # seconds

    private

    def build_http
      wait = RECONNECT_INTERVAL - (monotonic_now - @last_connect_at) if @last_connect_at
      sleep(wait) if wait&.positive?
      @last_connect_at = monotonic_now

      # Upstream turns off TLS certificate verification.
      super.tap { |http| http.verify_mode = OpenSSL::SSL::VERIFY_PEER }
    end

    def wait_on_request_queue
      deadline = monotonic_now + FLUSH_TIMEOUT
      sleep(0.1) while (@request_queue.size.positive? || @requests_in_flight.positive?) && monotonic_now < deadline
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
