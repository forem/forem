# frozen_string_literal: true

require_relative 'connection'

module Datadog
  class Statsd
    class UDSConnection < Connection
      class BadSocketError < StandardError; end

      # DogStatsd unix socket path
      attr_reader :socket_path

      def initialize(socket_path, **kwargs)
        super(**kwargs)

        @socket_path = socket_path
        @socket = nil
      end

      def close
        @socket.close if @socket
        @socket = nil
      end

      private

      def connect
        close if @socket

        @socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_DGRAM)
        @socket.connect(Socket.pack_sockaddr_un(@socket_path))
      end

      # send_message is writing the message in the socket, it may create the socket if nil
      # It is not thread-safe but since it is called by either the Sender bg thread or the
      # SingleThreadSender (which is using a mutex while Flushing), only one thread must call
      # it at a time.
      def send_message(message)
        connect unless @socket
        @socket.sendmsg_nonblock(message)
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ENOENT => e
        # TODO: FIXME: This error should be considered as a retryable error in the
        # Connection class. An even better solution would be to make BadSocketError inherit
        # from a specific retryable error class in the Connection class.
        raise BadSocketError, "#{e.class}: #{e}"
      end
    end
  end
end
