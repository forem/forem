# frozen_string_literal: true

require "timeout"
require "io/wait"

require "http/timeout/null"

module HTTP
  module Timeout
    class Global < Null
      def initialize(*args)
        super

        @timeout = @time_left = options.fetch(:global_timeout)
      end

      # To future me: Don't remove this again, past you was smarter.
      def reset_counter
        @time_left = @timeout
      end

      def connect(socket_class, host, port, nodelay = false)
        reset_timer
        ::Timeout.timeout(@time_left, TimeoutError) do
          @socket = socket_class.open(host, port)
          @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if nodelay
        end

        log_time
      end

      def connect_ssl
        reset_timer

        begin
          @socket.connect_nonblock
        rescue IO::WaitReadable
          IO.select([@socket], nil, nil, @time_left)
          log_time
          retry
        rescue IO::WaitWritable
          IO.select(nil, [@socket], nil, @time_left)
          log_time
          retry
        end
      end

      # Read from the socket
      def readpartial(size, buffer = nil)
        perform_io { read_nonblock(size, buffer) }
      end

      # Write to the socket
      def write(data)
        perform_io { write_nonblock(data) }
      end

      alias << write

      private

      if RUBY_VERSION < "2.1.0"
        def read_nonblock(size, buffer = nil)
          @socket.read_nonblock(size, buffer)
        end

        def write_nonblock(data)
          @socket.write_nonblock(data)
        end
      else
        def read_nonblock(size, buffer = nil)
          @socket.read_nonblock(size, buffer, :exception => false)
        end

        def write_nonblock(data)
          @socket.write_nonblock(data, :exception => false)
        end
      end

      # Perform the given I/O operation with the given argument
      def perform_io
        reset_timer

        loop do
          begin
            result = yield

            case result
            when :wait_readable then wait_readable_or_timeout
            when :wait_writable then wait_writable_or_timeout
            when NilClass       then return :eof
            else                return result
            end
          rescue IO::WaitReadable
            wait_readable_or_timeout
          rescue IO::WaitWritable
            wait_writable_or_timeout
          end
        end
      rescue EOFError
        :eof
      end

      # Wait for a socket to become readable
      def wait_readable_or_timeout
        @socket.to_io.wait_readable(@time_left)
        log_time
      end

      # Wait for a socket to become writable
      def wait_writable_or_timeout
        @socket.to_io.wait_writable(@time_left)
        log_time
      end

      # Due to the run/retry nature of nonblocking I/O, it's easier to keep track of time
      # via method calls instead of a block to monitor.
      def reset_timer
        @started = Time.now
      end

      def log_time
        @time_left -= (Time.now - @started)
        if @time_left <= 0
          raise TimeoutError, "Timed out after using the allocated #{@timeout} seconds"
        end

        reset_timer
      end
    end
  end
end
