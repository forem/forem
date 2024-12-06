module Flipper
  module Instrumenters
    # Instrumentor that is useful for tests as it stores each of the events that
    # are instrumented.
    class Memory
      Event = Struct.new(:name, :payload, :result)

      attr_reader :events

      def initialize
        @events = []
      end

      def instrument(name, payload = {})
        # Copy the payload to guard against later modifications to it, and to
        # ensure that all instrumentation code uses the payload passed to the
        # block rather than the one passed to #instrument.
        payload = payload.dup

        result = yield payload if block_given?
      rescue Exception => e
        payload[:exception] = [e.class.name, e.message]
        payload[:exception_object] = e
        raise e
      ensure
        @events << Event.new(name, payload, result)
      end

      def events_by_name(name)
        @events.select { |event| event.name == name }
      end

      def event_by_name(name)
        events_by_name(name).first
      end

      def reset
        @events = []
      end
    end
  end
end
