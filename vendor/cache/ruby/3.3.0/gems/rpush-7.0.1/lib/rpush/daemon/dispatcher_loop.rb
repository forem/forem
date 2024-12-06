module Rpush
  module Daemon
    class DispatcherLoop
      include Reflectable
      include Loggable

      attr_reader :started_at, :dispatch_count

      STOP = :stop

      def initialize(queue, dispatcher)
        @queue = queue
        @dispatcher = dispatcher
        @dispatch_count = 0
      end

      def thread_status
        @thread ? @thread.status : 'not started'
      end

      def start
        @started_at = Time.now

        @thread = Thread.new do
          loop do
            payload = @queue.pop
            if stop_payload?(payload)
              break if should_stop?(payload)

              # Intended for another dispatcher loop.
              @queue.push(payload)
              Thread.pass
              sleep 0.1
            else
              dispatch(payload)
            end
          end

          Rpush::Daemon.store.release_connection
        end
      end

      def stop
        @queue.push([STOP, object_id]) if @thread
        @thread.join if @thread
        @dispatcher.cleanup
      rescue StandardError => e
        log_error(e)
        reflect(:error, e)
      ensure
        @thread = nil
      end

      private

      def stop_payload?(payload)
        payload.is_a?(Array) && payload.first == STOP
      end

      def should_stop?(payload)
        payload.last == object_id
      end

      def dispatch(payload)
        @dispatch_count += 1
        @dispatcher.dispatch(payload)
      rescue StandardError => e
        log_error(e)
        reflect(:error, e)
      end
    end
  end
end
