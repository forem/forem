module Backport
  module Server
    # A mixin for Backport servers that communicate with clients.
    #
    # Connectable servers check clients for incoming data on each tick.
    #
    module Connectable
      # @return [void]
      def starting
        clients.map(&:run)
      end

      # @return [void]
      def stopping
        clients.map(&:stop)
      end

      # @return [Array<Client>]
      def clients
        @clients ||= []
      end

      private

      # @return [Mutex]
      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
