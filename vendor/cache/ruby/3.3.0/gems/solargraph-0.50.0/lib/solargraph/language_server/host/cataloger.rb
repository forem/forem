# frozen_string_literal: true

module Solargraph
  module LanguageServer
    class Host
      # An asynchronous library cataloging handler.
      #
      class Cataloger
        def initialize host
          @host = host
          @stopped = true
        end

        # Stop the catalog thread.
        #
        # @return [void]
        def stop
          @stopped = true
        end

        # True if the cataloger is stopped.
        #
        # @return [Boolean]
        def stopped?
          @stopped
        end

        # Start the catalog thread.
        #
        # @return [void]
        def start
          return unless stopped?
          @stopped = false
          Thread.new do
            until stopped?
              tick
              sleep 0.1
            end
          end
        end

        # Perform cataloging.
        #
        # @return [void]
        def tick
          host.catalog
        end

        private

        # @return [Host]
        attr_reader :host
      end
    end
  end
end
