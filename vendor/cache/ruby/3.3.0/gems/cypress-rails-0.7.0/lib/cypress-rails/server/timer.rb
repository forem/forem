module CypressRails
  class Server
    class Timer
      def initialize(expire_in)
        @start = current
        @expire_in = expire_in
      end

      def expired?
        current - @start >= @expire_in
      end

      def stalled?
        @start == current
      end

      private

      def current
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
