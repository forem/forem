# frozen_string_literal: true

require "redis/connection/registry"
require "redis/connection/command_helper"
require "redis/errors"

require "socket"
require "timeout"

begin
  require "openssl"
rescue LoadError
  # Not all systems have OpenSSL support
end

class Redis
  module Connection
    module SocketMixin
      CRLF = "\r\n"

      def initialize(*args)
        super(*args)

        @timeout = @write_timeout = nil
        @buffer = "".b
      end

      def timeout=(timeout)
        @timeout = (timeout if timeout && timeout > 0)
      end

      def write_timeout=(timeout)
        @write_timeout = (timeout if timeout && timeout > 0)
      end

      def read(nbytes)
        result = @buffer.slice!(0, nbytes)

        buffer = String.new(capacity: nbytes, encoding: Encoding::ASCII_8BIT)
        result << _read_from_socket(nbytes - result.bytesize, buffer) while result.bytesize < nbytes

        result
      end

      def gets
        while (crlf = @buffer.index(CRLF)).nil?
          @buffer << _read_from_socket(16_384)
        end

        @buffer.slice!(0, crlf + CRLF.bytesize)
      end

      def _read_from_socket(nbytes, buffer = nil)
        loop do
          case chunk = read_nonblock(nbytes, buffer, exception: false)
          when :wait_readable
            unless wait_readable(@timeout)
              raise Redis::TimeoutError
            end
          when :wait_writable
            unless wait_writable(@timeout)
              raise Redis::TimeoutError
            end
          when nil
            raise Errno::ECONNRESET
          when String
            return chunk
          end
        end
      end

      def write(buffer)
        return super(buffer) unless @write_timeout

        bytes_to_write = buffer.bytesize
        total_bytes_written = 0
        loop do
          case bytes_written = write_nonblock(buffer, exception: false)
          when :wait_readable
            unless wait_readable(@write_timeout)
              raise Redis::TimeoutError
            end
          when :wait_writable
            unless wait_writable(@write_timeout)
              raise Redis::TimeoutError
            end
          when nil
            raise Errno::ECONNRESET
          when Integer
            total_bytes_written += bytes_written

            if total_bytes_written >= bytes_to_write
              return total_bytes_written
            end

            buffer = buffer.byteslice(bytes_written..-1)
          end
        end
      end
    end

    if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"

      require "timeout"

      class TCPSocket < ::TCPSocket
        include SocketMixin

        def self.connect(host, port, timeout)
          Timeout.timeout(timeout) do
            sock = new(host, port)
            sock
          end
        rescue Timeout::Error
          raise TimeoutError
        end
      end

      if defined?(::UNIXSocket)

        class UNIXSocket < ::UNIXSocket
          include SocketMixin

          def self.connect(path, timeout)
            Timeout.timeout(timeout) do
              sock = new(path)
              sock
            end
          rescue Timeout::Error
            raise TimeoutError
          end

          # JRuby raises Errno::EAGAIN on #read_nonblock even when it
          # says it is readable (1.6.6, in both 1.8 and 1.9 mode).
          # Use the blocking #readpartial method instead.

          def _read_from_socket(nbytes, _buffer = nil)
            # JRuby: Throw away the buffer as we won't need it
            # but still need to support the max arity of 2
            readpartial(nbytes)
          rescue EOFError
            raise Errno::ECONNRESET
          end
        end

      end

    else

      class TCPSocket < ::Socket
        include SocketMixin

        def self.connect_addrinfo(addrinfo, port, timeout)
          sock = new(::Socket.const_get(addrinfo[0]), Socket::SOCK_STREAM, 0)
          sockaddr = ::Socket.pack_sockaddr_in(port, addrinfo[3])

          begin
            sock.connect_nonblock(sockaddr)
          rescue Errno::EINPROGRESS
            raise TimeoutError unless sock.wait_writable(timeout)

            begin
              sock.connect_nonblock(sockaddr)
            rescue Errno::EISCONN
            end
          end

          sock
        end

        def self.connect(host, port, timeout)
          # Don't pass AI_ADDRCONFIG as flag to getaddrinfo(3)
          #
          # From the man page for getaddrinfo(3):
          #
          #   If hints.ai_flags includes the AI_ADDRCONFIG flag, then IPv4
          #   addresses are returned in the list pointed to by res only if the
          #   local system has at least one IPv4 address configured, and IPv6
          #   addresses are returned only if the local system has at least one
          #   IPv6 address configured. The loopback address is not considered
          #   for this case as valid as a configured address.
          #
          # We do want the IPv6 loopback address to be returned if applicable,
          # even if it is the only configured IPv6 address on the machine.
          # Also see: https://github.com/redis/redis-rb/pull/394.
          addrinfo = ::Socket.getaddrinfo(host, nil, Socket::AF_UNSPEC, Socket::SOCK_STREAM)

          # From the man page for getaddrinfo(3):
          #
          #   Normally, the application should try using the addresses in the
          #   order in which they are returned. The sorting function used
          #   within getaddrinfo() is defined in RFC 3484 [...].
          #
          addrinfo.each_with_index do |ai, i|
            begin
              return connect_addrinfo(ai, port, timeout)
            rescue SystemCallError
              # Raise if this was our last attempt.
              raise if addrinfo.length == i + 1
            end
          end
        end
      end

      class UNIXSocket < ::Socket
        include SocketMixin

        def self.connect(path, timeout)
          sock = new(::Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
          sockaddr = ::Socket.pack_sockaddr_un(path)

          begin
            sock.connect_nonblock(sockaddr)
          rescue Errno::EINPROGRESS
            raise TimeoutError unless sock.wait_writable(timeout)

            begin
              sock.connect_nonblock(sockaddr)
            rescue Errno::EISCONN
            end
          end

          sock
        end
      end

    end

    if defined?(OpenSSL)
      class SSLSocket < ::OpenSSL::SSL::SSLSocket
        include SocketMixin

        unless method_defined?(:wait_readable)
          def wait_readable(timeout = nil)
            to_io.wait_readable(timeout)
          end
        end

        unless method_defined?(:wait_writable)
          def wait_writable(timeout = nil)
            to_io.wait_writable(timeout)
          end
        end

        def self.connect(host, port, timeout, ssl_params)
          # NOTE: this is using Redis::Connection::TCPSocket
          tcp_sock = TCPSocket.connect(host, port, timeout)

          ctx = OpenSSL::SSL::SSLContext.new

          # The provided parameters are merged into OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
          ctx.set_params(ssl_params || {})

          ssl_sock = new(tcp_sock, ctx)
          ssl_sock.hostname = host

          begin
            # Initiate the socket connection in the background. If it doesn't fail
            # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
            # indicating the connection is in progress.
            # Unlike waiting for a tcp socket to connect, you can't time out ssl socket
            # connections during the connect phase properly, because IO.select only partially works.
            # Instead, you have to retry.
            ssl_sock.connect_nonblock
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitReadable
            if ssl_sock.wait_readable(timeout)
              retry
            else
              raise TimeoutError
            end
          rescue IO::WaitWritable
            if ssl_sock.wait_writable(timeout)
              retry
            else
              raise TimeoutError
            end
          end

          unless ctx.verify_mode == OpenSSL::SSL::VERIFY_NONE || (
            ctx.respond_to?(:verify_hostname) &&
            !ctx.verify_hostname
          )
            ssl_sock.post_connection_check(host)
          end

          ssl_sock
        end
      end
    end

    class Ruby
      include Redis::Connection::CommandHelper

      MINUS    = "-"
      PLUS     = "+"
      COLON    = ":"
      DOLLAR   = "$"
      ASTERISK = "*"

      def self.connect(config)
        if config[:scheme] == "unix"
          raise ArgumentError, "SSL incompatible with unix sockets" if config[:ssl]

          sock = UNIXSocket.connect(config[:path], config[:connect_timeout])
        elsif config[:scheme] == "rediss" || config[:ssl]
          sock = SSLSocket.connect(config[:host], config[:port], config[:connect_timeout], config[:ssl_params])
        else
          sock = TCPSocket.connect(config[:host], config[:port], config[:connect_timeout])
        end

        instance = new(sock)
        instance.timeout = config[:read_timeout]
        instance.write_timeout = config[:write_timeout]
        instance.set_tcp_keepalive config[:tcp_keepalive]
        instance.set_tcp_nodelay if sock.is_a? TCPSocket
        instance
      end

      if %i[SOL_SOCKET SO_KEEPALIVE SOL_TCP TCP_KEEPIDLE TCP_KEEPINTVL TCP_KEEPCNT].all? { |c| Socket.const_defined? c }
        def set_tcp_keepalive(keepalive)
          return unless keepalive.is_a?(Hash)

          @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE,  true)
          @sock.setsockopt(Socket::SOL_TCP,    Socket::TCP_KEEPIDLE,  keepalive[:time])
          @sock.setsockopt(Socket::SOL_TCP,    Socket::TCP_KEEPINTVL, keepalive[:intvl])
          @sock.setsockopt(Socket::SOL_TCP,    Socket::TCP_KEEPCNT,   keepalive[:probes])
        end

        def get_tcp_keepalive
          {
            time: @sock.getsockopt(Socket::SOL_TCP, Socket::TCP_KEEPIDLE).int,
            intvl: @sock.getsockopt(Socket::SOL_TCP, Socket::TCP_KEEPINTVL).int,
            probes: @sock.getsockopt(Socket::SOL_TCP, Socket::TCP_KEEPCNT).int
          }
        end
      else
        def set_tcp_keepalive(keepalive); end

        def get_tcp_keepalive
          {
          }
        end
      end

      # disables Nagle's Algorithm, prevents multiple round trips with MULTI
      if %i[IPPROTO_TCP TCP_NODELAY].all? { |c| Socket.const_defined? c }
        def set_tcp_nodelay
          @sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        end
      else
        def set_tcp_nodelay; end
      end

      def initialize(sock)
        @sock = sock
      end

      def connected?
        !!@sock
      end

      def disconnect
        @sock.close
      rescue
      ensure
        @sock = nil
      end

      def timeout=(timeout)
        @sock.timeout = timeout if @sock.respond_to?(:timeout=)
      end

      def write_timeout=(timeout)
        @sock.write_timeout = timeout
      end

      def write(command)
        @sock.write(build_command(command))
      end

      def read
        line = @sock.gets
        reply_type = line.slice!(0, 1)
        format_reply(reply_type, line)
      rescue Errno::EAGAIN
        raise TimeoutError
      rescue OpenSSL::SSL::SSLError => ssl_error
        if ssl_error.message.match?(/SSL_read: unexpected eof while reading/i)
          raise EOFError, ssl_error.message
        else
          raise
        end
      end

      def format_reply(reply_type, line)
        case reply_type
        when MINUS    then format_error_reply(line)
        when PLUS     then format_status_reply(line)
        when COLON    then format_integer_reply(line)
        when DOLLAR   then format_bulk_reply(line)
        when ASTERISK then format_multi_bulk_reply(line)
        else raise ProtocolError, reply_type
        end
      end

      def format_error_reply(line)
        CommandError.new(line.strip)
      end

      def format_status_reply(line)
        line.strip
      end

      def format_integer_reply(line)
        line.to_i
      end

      def format_bulk_reply(line)
        bulklen = line.to_i
        return if bulklen == -1

        reply = encode(@sock.read(bulklen))
        @sock.read(2) # Discard CRLF.
        reply
      end

      def format_multi_bulk_reply(line)
        n = line.to_i
        return if n == -1

        Array.new(n) { read }
      end
    end
  end
end

Redis::Connection.drivers << Redis::Connection::Ruby
