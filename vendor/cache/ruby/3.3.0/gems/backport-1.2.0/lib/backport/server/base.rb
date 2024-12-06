require 'observer'

module Backport
  module Server
    # An extendable server class that provides basic start/stop functionality
    # and common callbacks.
    #
    class Base
      include Observable

      # Start the server.
      #
      # @return [void]
      def start
        return if started?
        starting
        @started = true
      end

      # Stop the server.
      #
      # @return [void]
      def stop
        return if stopped?
        stopping
        @started = false
        changed
        notify_observers self
      end

      def started?
        @started ||= false
      end

      def stopped?
        !started?
      end

      # A callback triggered when a Machine starts running or the server is
      # added to a running machine. Subclasses should override this method to
      # provide their own functionality.
      #
      # @return [void]
      def starting; end

      # A callback triggered when the server is stopping. Subclasses should
      # override this method to provide their own functionality.
      #
      # @return [void]
      def stopping; end

      # A callback triggered from the main loop of a running Machine.
      # Subclasses should override this method to provide their own
      # functionality.
      #
      # @return [void]
      def tick; end
    end
  end
end
