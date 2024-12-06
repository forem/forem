require 'http/parser'
require 'openssl'
require 'resolv'

module Twitter
  module Streaming
    class Connection
      attr_reader :tcp_socket_class, :ssl_socket_class

      def initialize(options = {})
        @tcp_socket_class = options.fetch(:tcp_socket_class) { TCPSocket }
        @ssl_socket_class = options.fetch(:ssl_socket_class) { OpenSSL::SSL::SSLSocket }
        @using_ssl        = options.fetch(:using_ssl)        { false }
        @write_pipe = nil
      end

      def stream(request, response) # rubocop:disable Metrics/MethodLength
        client = connect(request)
        request.stream(client)
        read_pipe, @write_pipe = IO.pipe
        loop do
          read_ios, _write_ios, _exception_ios = IO.select([read_pipe, client])
          case read_ios.first
          when client
            response << client.readpartial(1024)
          when read_pipe
            break
          end
        end
        client.close
      end

      def connect(request)
        client = new_tcp_socket(request.socket_host, request.socket_port)
        return client if !@using_ssl && request.using_proxy?

        client_context = OpenSSL::SSL::SSLContext.new
        ssl_client     = @ssl_socket_class.new(client, client_context)
        ssl_client.connect
      end

      def close
        @write_pipe&.write('q')
      end

    private

      def new_tcp_socket(host, port)
        @tcp_socket_class.new(Resolv.getaddress(host), port)
      end
    end
  end
end
