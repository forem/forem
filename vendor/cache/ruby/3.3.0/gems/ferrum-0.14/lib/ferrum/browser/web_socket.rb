# frozen_string_literal: true

require "json"
require "socket"
require "websocket/driver"

module Ferrum
  class Browser
    class WebSocket
      WEBSOCKET_BUG_SLEEP = 0.05
      SKIP_LOGGING_SCREENSHOTS = !ENV["FERRUM_LOGGING_SCREENSHOTS"]

      attr_reader :url, :messages

      def initialize(url, max_receive_size, logger)
        @url      = url
        @logger   = logger
        uri       = URI.parse(@url)
        @sock     = TCPSocket.new(uri.host, uri.port)
        max_receive_size ||= ::WebSocket::Driver::MAX_LENGTH
        @driver   = ::WebSocket::Driver.client(self, max_length: max_receive_size)
        @messages = Queue.new

        @screenshot_commands = Concurrent::Hash.new if SKIP_LOGGING_SCREENSHOTS

        @driver.on(:open,    &method(:on_open))
        @driver.on(:message, &method(:on_message))
        @driver.on(:close,   &method(:on_close))

        @thread = Thread.new do
          Thread.current.abort_on_exception = true
          Thread.current.report_on_exception = true if Thread.current.respond_to?(:report_on_exception=)

          begin
            loop do
              data = @sock.readpartial(512)
              break unless data

              @driver.parse(data)
            end
          rescue EOFError, Errno::ECONNRESET, Errno::EPIPE
            @messages.close
          end
        end

        @driver.start
      end

      def on_open(_event)
        # https://github.com/faye/websocket-driver-ruby/issues/46
        sleep(WEBSOCKET_BUG_SLEEP)
      end

      def on_message(event)
        data = JSON.parse(event.data)
        @messages.push(data)

        output = event.data
        if SKIP_LOGGING_SCREENSHOTS && @screenshot_commands[data["id"]]
          @screenshot_commands.delete(data["id"])
          output.sub!(/{"data":"(.*)"}/, %("Set FERRUM_LOGGING_SCREENSHOTS=true to see screenshots in Base64"))
        end

        @logger&.puts("    ◀ #{Utils::ElapsedTime.elapsed_time} #{output}\n")
      end

      def on_close(_event)
        @messages.close
        @thread.kill
      end

      def send_message(data)
        @screenshot_commands[data[:id]] = true if SKIP_LOGGING_SCREENSHOTS

        json = data.to_json
        @driver.text(json)
        @logger&.puts("\n\n▶ #{Utils::ElapsedTime.elapsed_time} #{json}")
      end

      def write(data)
        @sock.write(data)
      rescue EOFError, Errno::ECONNRESET, Errno::EPIPE
        @messages.close
      end

      def close
        @driver.close
      end
    end
  end
end
