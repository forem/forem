# frozen_string_literal: true

require "tempfile"
require "webrick"
require "webrick/httpproxy"

module Ferrum
  class Proxy
    def self.start(**args)
      new(**args).tap(&:start)
    end

    attr_reader :host, :port, :user, :password

    def initialize(host: "127.0.0.1", port: 0, user: nil, password: nil)
      @file = nil
      @host = host
      @port = port
      @user = user
      @password = password
    end

    def start
      options = {
        ProxyURI: nil, ServerType: Thread,
        Logger: Logger.new(IO::NULL), AccessLog: [],
        BindAddress: host, Port: port
      }

      if user && password
        @file = Tempfile.new("htpasswd")
        htpasswd = WEBrick::HTTPAuth::Htpasswd.new(@file.path)
        htpasswd.set_passwd "Proxy Realm", user, password
        htpasswd.flush
        authenticator = WEBrick::HTTPAuth::ProxyBasicAuth.new(Realm: "Proxy Realm",
                                                              UserDB: htpasswd,
                                                              Logger: Logger.new(IO::NULL))
        options.merge!(ProxyAuthProc: authenticator.method(:authenticate).to_proc)
      end

      @server = HTTPProxyServer.new(**options)
      @server.start
      at_exit { stop }

      @port = @server.config[:Port]
    end

    def rotate(host:, port:, user: nil, password: nil)
      credentials = "#{user}:#{password}@" if user && password
      proxy_uri = "schema://#{credentials}#{host}:#{port}"
      @server.config[:ProxyURI] = URI.parse(proxy_uri)
    end

    def stop
      @file&.unlink
      @server.shutdown
    end

    # Fix hanging proxy at exit
    class HTTPProxyServer < WEBrick::HTTPProxyServer
      # rubocop:disable all
      def do_CONNECT(req, res)
        # Proxy Authentication
        proxy_auth(req, res)

        ua = Thread.current[:WEBrickSocket]  # User-Agent
        raise WEBrick::HTTPStatus::InternalServerError,
              "[BUG] cannot get socket" unless ua

        host, port = req.unparsed_uri.split(":", 2)
        # Proxy authentication for upstream proxy server
        if proxy = proxy_uri(req, res)
          proxy_request_line = "CONNECT #{host}:#{port} HTTP/1.0"
          if proxy.userinfo
            credentials = "Basic " + [proxy.userinfo].pack("m0")
          end
          host, port = proxy.host, proxy.port
        end

        begin
          @logger.debug("CONNECT: upstream proxy is `#{host}:#{port}'.")
          os = TCPSocket.new(host, port)     # origin server

          if proxy
            @logger.debug("CONNECT: sending a Request-Line")
            os << proxy_request_line << CRLF
            @logger.debug("CONNECT: > #{proxy_request_line}")
            if credentials
              @logger.debug("CONNECT: sending credentials")
              os << "Proxy-Authorization: " << credentials << CRLF
            end
            os << CRLF
            proxy_status_line = os.gets(LF)
            @logger.debug("CONNECT: read Status-Line from the upstream server")
            @logger.debug("CONNECT: < #{proxy_status_line}")
            if %r{^HTTP/\d+\.\d+\s+200\s*} =~ proxy_status_line
              while line = os.gets(LF)
                break if /\A(#{CRLF}|#{LF})\z/om =~ line
              end
            else
              raise WEBrick::HTTPStatus::BadGateway
            end
          end
          @logger.debug("CONNECT #{host}:#{port}: succeeded")
          res.status = WEBrick::HTTPStatus::RC_OK
        rescue => ex
          @logger.debug("CONNECT #{host}:#{port}: failed `#{ex.message}'")
          res.set_error(ex)
          raise WEBrick::HTTPStatus::EOFError
        ensure
          # At exit os variable sometimes can be nil which results in hanging forever
          raise WEBrick::HTTPStatus::EOFError unless os

          if handler = @config[:ProxyContentHandler]
            handler.call(req, res)
          end
          res.send_response(ua)
          access_log(@config, req, res)

          # Should clear request-line not to send the response twice.
          # see: HTTPServer#run
          req.parse(NullReader) rescue nil
        end

        begin
          while fds = IO::select([ua, os])
            if fds[0].member?(ua)
              buf = ua.readpartial(1024);
              @logger.debug("CONNECT: #{buf.bytesize} byte from User-Agent")
              os.write(buf)
            elsif fds[0].member?(os)
              buf = os.readpartial(1024);
              @logger.debug("CONNECT: #{buf.bytesize} byte from #{host}:#{port}")
              ua.write(buf)
            end
          end
        rescue
          os.close
          @logger.debug("CONNECT #{host}:#{port}: closed")
        end

        raise WEBrick::HTTPStatus::EOFError
      end
      # rubocop:enable all
    end
  end
end
