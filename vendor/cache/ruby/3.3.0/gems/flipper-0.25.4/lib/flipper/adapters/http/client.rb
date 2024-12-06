require 'uri'
require 'openssl'
require 'flipper/version'

module Flipper
  module Adapters
    class Http
      class Client
        DEFAULT_HEADERS = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'User-Agent' => "Flipper HTTP Adapter v#{VERSION}",
        }.freeze

        HTTPS_SCHEME = "https".freeze

        def initialize(options = {})
          @uri = URI(options.fetch(:url))
          @headers = DEFAULT_HEADERS.merge(options[:headers] || {})
          @basic_auth_username = options[:basic_auth_username]
          @basic_auth_password = options[:basic_auth_password]
          @read_timeout = options[:read_timeout]
          @open_timeout = options[:open_timeout]
          @write_timeout = options[:write_timeout]
          @debug_output = options[:debug_output]
        end

        def get(path)
          perform Net::HTTP::Get, path, @headers
        end

        def post(path, body = nil)
          perform Net::HTTP::Post, path, @headers, body: body
        end

        def delete(path, body = nil)
          perform Net::HTTP::Delete, path, @headers, body: body
        end

        private

        def perform(http_method, path, headers = {}, options = {})
          uri = uri_for_path(path)
          http = build_http(uri)
          request = build_request(http_method, uri, headers, options)
          http.request(request)
        end

        def uri_for_path(path)
          uri = @uri.dup
          path_uri = URI(path)
          uri.path += path_uri.path
          uri.query = "#{uri.query}&#{path_uri.query}" if path_uri.query
          uri
        end

        def build_http(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = @read_timeout if @read_timeout
          http.open_timeout = @open_timeout if @open_timeout
          apply_write_timeout(http)
          http.set_debug_output(@debug_output) if @debug_output

          if uri.scheme == HTTPS_SCHEME
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          end

          http
        end

        def build_request(http_method, uri, headers, options)
          request_headers = {
            "Client-Language" => "ruby",
            "Client-Language-Version" => "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})",
            "Client-Platform" => RUBY_PLATFORM,
            "Client-Engine" => defined?(RUBY_ENGINE) ? RUBY_ENGINE : "",
            "Client-Pid" => Process.pid.to_s,
            "Client-Thread" => Thread.current.object_id.to_s,
            "Client-Hostname" => Socket.gethostname,
          }.merge(headers)

          body = options[:body]
          request = http_method.new(uri.request_uri)
          request.initialize_http_header(request_headers)
          request.body = body if body

          if @basic_auth_username && @basic_auth_password
            request.basic_auth(@basic_auth_username, @basic_auth_password)
          end

          request
        end

        def apply_write_timeout(http)
          if @write_timeout
            if RUBY_VERSION >= '2.6.0'
              http.write_timeout = @write_timeout
            else
              Kernel.warn("Warning: option :write_timeout requires Ruby version 2.6.0 or later")
            end
          end
        end
      end
    end
  end
end
