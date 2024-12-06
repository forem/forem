# frozen_string_literal: true

module Solargraph
  module LanguageServer
    class Host
      # An asynchronous diagnosis reporter.
      #
      class Diagnoser
        # @param host [Host]
        def initialize host
          @host = host
          @mutex = Mutex.new
          @queue = []
          @stopped = true
        end

        # Schedule a file to be diagnosed.
        #
        # @param uri [String]
        # @return [void]
        def schedule uri
          mutex.synchronize { queue.push uri }
        end

        # Stop the diagnosis thread.
        #
        # @return [void]
        def stop
          @stopped = true
        end

        # True is the diagnoser is stopped.
        #
        # @return [Boolean]
        def stopped?
          @stopped
        end

        # Start the diagnosis thread.
        #
        # @return [self]
        def start
          return unless @stopped
          @stopped = false
          Thread.new do
            until stopped?
              tick
              sleep 0.1
            end
          end
          self
        end

        # Perform diagnoses.
        #
        # @return [void]
        def tick
          return if queue.empty? || host.synchronizing?
          if !host.options['diagnostics']
            mutex.synchronize { queue.clear }
            return
          end
          current = mutex.synchronize { queue.shift }
          return if queue.include?(current)
          begin
            host.diagnose current
          rescue InvalidOffsetError
            # @todo This error can occur when the Source is out of sync with
            #   with the ApiMap. It's probably not the best way to handle it,
            #   but it's quick and easy.
            Logging.logger.warn "Deferring diagnosis due to invalid offset: #{current}"
            mutex.synchronize { queue.push current }
          end
        end

        private

        # @return [Host]
        attr_reader :host

        # @return [Mutex]
        attr_reader :mutex

        # @return [Array]
        attr_reader :queue
      end
    end
  end
end
