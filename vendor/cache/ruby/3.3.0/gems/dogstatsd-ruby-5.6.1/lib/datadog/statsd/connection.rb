# frozen_string_literal: true

module Datadog
  class Statsd
    class Connection
      def initialize(telemetry: nil, logger: nil)
        @telemetry = telemetry
        @logger = logger
      end

      def reset_telemetry
        telemetry.reset if telemetry
      end

      # not thread safe: `Sender` instances that use this are required to properly synchronize or sequence calls to this method
      def write(payload)
        logger.debug { "Statsd: #{payload}" } if logger

        send_message(payload)

        telemetry.sent(packets: 1, bytes: payload.length) if telemetry

        true
      rescue StandardError => boom
        # Try once to reconnect if the socket has been closed
        retries ||= 1
        if retries <= 1 &&
          (boom.is_a?(Errno::ENOTCONN) or
           boom.is_a?(Errno::ECONNREFUSED) or
           boom.is_a?(IOError) && boom.message =~ /closed stream/i)
          retries += 1
          begin
            close
            connect
            retry
          rescue StandardError => e
            boom = e
          end
        end

        telemetry.dropped_writer(packets: 1, bytes: payload.length) if telemetry
        logger.error { "Statsd: #{boom.class} #{boom}" } if logger
        nil
      end

      private

      attr_reader :telemetry
      attr_reader :logger

      def connect
        raise 'Should be implemented by subclass'
      end

      def close
        raise 'Should be implemented by subclass'
      end
    end
  end
end
