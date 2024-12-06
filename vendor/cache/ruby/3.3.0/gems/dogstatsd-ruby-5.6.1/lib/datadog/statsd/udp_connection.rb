# frozen_string_literal: true

require_relative 'connection'

module Datadog
  class Statsd
    class UDPConnection < Connection
      # StatsD host.
      attr_reader :host

      # StatsD port.
      attr_reader :port

      def initialize(host, port, **kwargs)
        super(**kwargs)

        @host = host
        @port = port
        @socket = nil
      end

      def close
        @socket.close if @socket
        @socket = nil
      end

      private

      def connect
        close if @socket

        family = Addrinfo.udp(host, port).afamily

        @socket = UDPSocket.new(family)
        @socket.connect(host, port)
      end

      # send_message is writing the message in the socket, it may create the socket if nil
      # It is not thread-safe but since it is called by either the Sender bg thread or the
      # SingleThreadSender (which is using a mutex while Flushing), only one thread must call
      # it at a time.
      def send_message(message)
        connect unless @socket
        @socket.send(message, 0)
      end
    end
  end
end
