# frozen_string_literal: true

require "ferrum/browser/subscriber"
require "ferrum/browser/web_socket"

module Ferrum
  class Browser
    class Client
      INTERRUPTIONS = %w[Fetch.requestPaused Fetch.authRequired].freeze

      def initialize(ws_url, connectable, logger: nil, ws_max_receive_size: nil, id_starts_with: 0)
        @connectable = connectable
        @command_id = id_starts_with
        @pendings = Concurrent::Hash.new
        @ws = WebSocket.new(ws_url, ws_max_receive_size, logger)
        @subscriber, @interrupter = Subscriber.build(2)

        @thread = Thread.new do
          Thread.current.abort_on_exception = true
          Thread.current.report_on_exception = true if Thread.current.respond_to?(:report_on_exception=)

          loop do
            message = @ws.messages.pop
            break unless message

            if INTERRUPTIONS.include?(message["method"])
              @interrupter.async.call(message)
            elsif message.key?("method")
              @subscriber.async.call(message)
            else
              @pendings[message["id"]]&.set(message)
            end
          end
        end
      end

      def command(method, params = {})
        pending = Concurrent::IVar.new
        message = build_message(method, params)
        @pendings[message[:id]] = pending
        @ws.send_message(message)
        data = pending.value!(@connectable.timeout)
        @pendings.delete(message[:id])

        raise DeadBrowserError if data.nil? && @ws.messages.closed?
        raise TimeoutError unless data

        error, response = data.values_at("error", "result")
        raise_browser_error(error) if error
        response
      end

      def on(event, &block)
        case event
        when *INTERRUPTIONS
          @interrupter.on(event, &block)
        else
          @subscriber.on(event, &block)
        end
      end

      def subscribed?(event)
        [@interrupter, @subscriber].any? { |s| s.subscribed?(event) }
      end

      def close
        @ws.close
        # Give a thread some time to handle a tail of messages
        @pendings.clear
        @thread.kill unless @thread.join(1)
      end

      private

      def build_message(method, params)
        { method: method, params: params }.merge(id: next_command_id)
      end

      def next_command_id
        @command_id += 1
      end

      def raise_browser_error(error)
        case error["message"]
        # Node has disappeared while we were trying to get it
        when "No node with given id found",
             "Could not find node with given id",
             "Inspected target navigated or closed"
          raise NodeNotFoundError, error
        # Context is lost, page is reloading
        when "Cannot find context with specified id"
          raise NoExecutionContextError, error
        when "No target with given id found"
          raise NoSuchPageError
        when /Could not compute content quads/
          raise CoordinatesNotFoundError
        else
          raise BrowserError, error
        end
      end
    end
  end
end
