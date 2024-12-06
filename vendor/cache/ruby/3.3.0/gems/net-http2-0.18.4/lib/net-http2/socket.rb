module NetHttp2

  module Socket

    def self.create(uri, options)
      return ssl_socket(uri, options) if options[:ssl]
      return proxy_tcp_socket(uri, options) if options[:proxy_addr]

      tcp_socket(uri, options)
    end

    def self.ssl_socket(uri, options)
      tcp = if options[:proxy_addr]
        proxy_tcp_socket(uri, options)
      else
        tcp_socket(uri, options)
      end

      socket            = OpenSSL::SSL::SSLSocket.new(tcp, options[:ssl_context])
      socket.sync_close = true
      socket.hostname   = options[:proxy_addr] || uri.host

      socket.connect

      socket
    end

    def self.tcp_socket(uri, options)
      family   = ::Socket::AF_INET
      address  = ::Socket.getaddrinfo(uri.host, nil, family).first[3]
      sockaddr = ::Socket.pack_sockaddr_in(uri.port, address)

      socket = ::Socket.new(family, ::Socket::SOCK_STREAM, 0)
      socket.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)

      begin
        socket.connect_nonblock(sockaddr)
      rescue IO::WaitWritable
        if IO.select(nil, [socket], nil, options[:connect_timeout])
          begin
            socket.connect_nonblock(sockaddr)
          rescue Errno::EISCONN
            # socket is connected
          rescue
            socket.close
            raise
          end
        else
          socket.close
          raise Errno::ETIMEDOUT
        end
      end

      socket
    end

    def self.proxy_tcp_socket(uri, options)
      proxy_addr = options[:proxy_addr]
      proxy_port = options[:proxy_port]
      proxy_user = options[:proxy_user]
      proxy_pass = options[:proxy_pass]

      proxy_uri = URI.parse("#{proxy_addr}:#{proxy_port}")
      proxy_socket = tcp_socket(proxy_uri, options)

      # The majority of proxies do not explicitly support HTTP/2 protocol,
      # while they successfully create a TCP tunnel
      # which can pass through binary data of HTTP/2 connection.
      # So we’ll keep HTTP/1.1
      http_version = '1.1'

      buf = "CONNECT #{uri.host}:#{uri.port} HTTP/#{http_version}\r\n"
      buf << "Host: #{uri.host}:#{uri.port}\r\n"
      if proxy_user
        credential = ["#{proxy_user}:#{proxy_pass}"].pack('m')
        credential.delete!("\r\n")
        buf << "Proxy-Authorization: Basic #{credential}\r\n"
      end
      buf << "\r\n"
      proxy_socket.write(buf)
      validate_proxy_response!(proxy_socket)

      proxy_socket
    end

    private

    def self.validate_proxy_response!(socket)
      result = ''
      loop do
        line = socket.gets
        break if !line || line.strip.empty?

        result << line
      end
      return if result =~ /HTTP\/\d(?:\.\d)?\s+2\d\d\s/

      raise(StandardError, "Proxy connection failure:\n#{result}")
    end
  end
end
