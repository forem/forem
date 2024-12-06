# frozen_string_literal: true
require 'ipaddr'

module Excon
  class Connection
    include Utils

    attr_reader :data

    def connection
      Excon.display_warning('Excon::Connection#connection is deprecated use Excon::Connection#data instead.')
      @data
    end
    def connection=(new_params)
      Excon.display_warning('Excon::Connection#connection= is deprecated. Use of this method may cause unexpected results.')
      @data = new_params
    end

    def params
      Excon.display_warning('Excon::Connection#params is deprecated use Excon::Connection#data instead.')
      @data
    end
    def params=(new_params)
      Excon.display_warning('Excon::Connection#params= is deprecated. Use of this method may cause unexpected results.')
      @data = new_params
    end

    def proxy
      Excon.display_warning('Excon::Connection#proxy is deprecated use Excon::Connection#data[:proxy] instead.')
      @data[:proxy]
    end
    def proxy=(new_proxy)
      Excon.display_warning('Excon::Connection#proxy= is deprecated. Use of this method may cause unexpected results.')
      @data[:proxy] = new_proxy
    end

    def logger
      if @data[:instrumentor] && @data[:instrumentor].respond_to?(:logger)
        @data[:instrumentor].logger
      end
    end
    def logger=(logger)
      @data[:instrumentor] = Excon::LoggingInstrumentor
      @data[:logger] = logger
    end

    # Initializes a new Connection instance
    # @param [Hash<Symbol, >] params One or more optional params
    # @option params [String] :body Default text to be sent over a socket. Only used if :body absent in Connection#request params
    # @option params [Hash<Symbol, String>] :headers The default headers to supply in a request. Only used if params[:headers] is not supplied to Connection#request
    # @option params [String] :host The destination host's reachable DNS name or IP, in the form of a String. IPv6 addresses must be wrapped (e.g. [::1]).  See URI#host.
    # @option params [String] :hostname Same as host, but usable for socket connections. IPv6 addresses must not be wrapped (e.g. ::1).  See URI#hostname.
    # @option params [String] :path Default path; appears after 'scheme://host:port/'. Only used if params[:path] is not supplied to Connection#request
    # @option params [Fixnum] :port The port on which to connect, to the destination host
    # @option params [Hash]   :query Default query; appended to the 'scheme://host:port/path/' in the form of '?key=value'. Will only be used if params[:query] is not supplied to Connection#request
    # @option params [String] :scheme The protocol; 'https' causes OpenSSL to be used
    # @option params [String] :socket The path to the unix socket (required for 'unix://' connections)
    # @option params [String] :ciphers Only use the specified SSL/TLS cipher suites; use OpenSSL cipher spec format e.g. 'HIGH:!aNULL:!3DES' or 'AES256-SHA:DES-CBC3-SHA'
    # @option params [String] :proxy Proxy server; e.g. 'http://myproxy.com:8888'
    # @option params [Fixnum] :retry_limit Set how many times we'll retry a failed request.  (Default 4)
    # @option params [Fixnum] :retry_interval Set how long to wait between retries. (Default 0)
    # @option params [Class] :instrumentor Responds to #instrument as in ActiveSupport::Notifications
    # @option params [String] :instrumentor_name Name prefix for #instrument events.  Defaults to 'excon'
    def initialize(params = {})
      @pid = Process.pid
      @data = Excon.defaults.dup
      # merge does not deep-dup, so make sure headers is not the original
      @data[:headers] = @data[:headers].dup

      # the same goes for :middlewares
      @data[:middlewares] = @data[:middlewares].dup

      @data.merge!(params)
      validate_params(:connection, @data, @data[:middlewares])

      if @data.key?(:host) && !@data.key?(:hostname)
        Excon.display_warning('hostname is missing! For IPv6 support, provide both host and hostname: Excon::Connection#new(:host => uri.host, :hostname => uri.hostname, ...).')
        @data[:hostname] = @data[:host]
      end

      setup_proxy

      if ENV.has_key?('EXCON_STANDARD_INSTRUMENTOR')
        @data[:instrumentor] = Excon::StandardInstrumentor
      end

      if @data[:debug] || ENV.has_key?('EXCON_DEBUG')
        @data[:debug_request] = @data[:debug_response] = true
        @data[:instrumentor] = Excon::StandardInstrumentor
      end

      if @data[:scheme] == UNIX
        # 'uri' >= v0.12.0 returns an empty string instead of nil for no host.
        # So treat the parameter as present if and only if it is both non-nill and non-empty.
        if @data[:host] && !@data[:host].empty?
          raise ArgumentError, "The `:host` parameter should not be set for `unix://` connections.\n" +
                               "When supplying a `unix://` URI, it should start with `unix:/` or `unix:///`."
        elsif !@data[:socket]
          raise ArgumentError, 'You must provide a `:socket` for `unix://` connections'
        else
          @socket_key = "#{@data[:scheme]}://#{@data[:socket]}"
        end
      else
        @socket_key = "#{@data[:scheme]}://#{@data[:host]}#{port_string(@data)}"
      end
      reset
    end

    def error_call(datum)
      if datum[:error]
        raise(datum[:error])
      end
    end

    def request_call(datum)
      begin
        if datum.has_key?(:response)
          # we already have data from a middleware, so bail
          return datum
        else
          socket(datum).data = datum
          # start with "METHOD /path"
          request = datum[:method].to_s.upcase + ' '
          if datum[:proxy] && datum[:scheme] != HTTPS
            request << datum[:scheme] << '://' << datum[:host] << port_string(datum)
          end
          request << datum[:path]

          # add query to path, if there is one
          request << query_string(datum)

          # finish first line with "HTTP/1.1\r\n"
          request << HTTP_1_1

          if datum.has_key?(:request_block)
            datum[:headers]['Transfer-Encoding'] = 'chunked'
          else
            body = datum[:body].is_a?(String) ? StringIO.new(datum[:body]) : datum[:body]

            # The HTTP spec isn't clear on it, but specifically, GET requests don't usually send bodies;
            # if they don't, sending Content-Length:0 can cause issues.
            unless datum[:method].to_s.casecmp('GET') == 0 && body.nil?
              unless datum[:headers].has_key?('Content-Length')
                datum[:headers]['Content-Length'] = detect_content_length(body)
              end
            end
          end

          # add headers to request
          request << Utils.headers_hash_to_s(datum[:headers])

          # add additional "\r\n" to indicate end of headers
          request << CR_NL

          if datum.has_key?(:request_block)
            socket(datum).write(request) # write out request + headers
            while true # write out body with chunked encoding
              chunk = datum[:request_block].call
              chunk = binary_encode(chunk)
              if chunk.length > 0
                socket(datum).write(chunk.length.to_s(16) << CR_NL << chunk << CR_NL)
              else
                socket(datum).write(String.new("0#{CR_NL}#{CR_NL}"))
                break
              end
            end
          elsif body.nil?
            socket(datum).write(request) # write out request + headers
          else # write out body
            if body.respond_to?(:binmode) && !body.is_a?(StringIO)
              body.binmode
            end
            if body.respond_to?(:rewind)
              body.rewind  rescue nil
            end

            # if request + headers is less than chunk size, fill with body
            request = binary_encode(request)
            chunk = body.read([datum[:chunk_size] - request.length, 0].max)
            if chunk
              chunk = binary_encode(chunk)
              socket(datum).write(request << chunk)
            else
              socket(datum).write(request) # write out request + headers
            end

            while (chunk = body.read(datum[:chunk_size]))
              socket(datum).write(chunk)
            end
          end
        end
      rescue => error
        case error
        when Excon::Errors::InvalidHeaderKey, Excon::Errors::InvalidHeaderValue, Excon::Errors::StubNotFound, Excon::Errors::Timeout
          raise(error)
        when Errno::EPIPE
          # Read whatever remains in the pipe to aid in debugging
          response = socket.read
          error = Excon::Error.new(response + error.message)
          raise_socket_error(error)
        else
          raise_socket_error(error)
        end
      end

      datum
    end

    def response_call(datum)
      # ensure response_block is yielded to and body is empty from middlewares
      if datum.has_key?(:response_block) && !(datum[:response][:body].nil? || datum[:response][:body].empty?)
        response_body = datum[:response][:body].dup
        datum[:response][:body] = ''
        content_length = remaining = response_body.bytesize
        while remaining > 0
          datum[:response_block].call(response_body.slice!(0, [datum[:chunk_size], remaining].min), [remaining - datum[:chunk_size], 0].max, content_length)
          remaining -= datum[:chunk_size]
        end
      end
      datum
    end

    # Sends the supplied request to the destination host.
    # @yield [chunk] @see Response#self.parse
    # @param [Hash<Symbol, >] params One or more optional params, override defaults set in Connection.new
    # @option params [String] :body text to be sent over a socket
    # @option params [Hash<Symbol, String>] :headers The default headers to supply in a request
    # @option params [String] :path appears after 'scheme://host:port/'
    # @option params [Hash]   :query appended to the 'scheme://host:port/path/' in the form of '?key=value'
    def request(params={}, &block)
      # @data has defaults, merge in new params to override
      datum = @data.merge(params)
      datum[:headers] = @data[:headers].merge(datum[:headers] || {})

      validate_params(:request, params, datum[:middlewares])
      # If the user passed in new middleware, we want to validate that the original connection parameters
      # are still valid with the provided middleware.
      if params[:middlewares]
        validate_params(:connection, @data, datum[:middlewares])
      end

      if datum[:user] || datum[:password]
        user, pass = Utils.unescape_uri(datum[:user].to_s), Utils.unescape_uri(datum[:password].to_s)
        datum[:headers]['Authorization'] ||= 'Basic ' + ["#{user}:#{pass}"].pack('m').delete(Excon::CR_NL)
      end

      host_key = datum[:headers].keys.detect {|k| k.casecmp('Host') == 0 } || 'Host'
      if datum[:scheme] == UNIX
        datum[:headers][host_key] ||= ''
      else
        datum[:headers][host_key] ||= datum[:host] + port_string(datum)
      end

      # RFC 7230, section 5.4, states that the Host header SHOULD be the first one # to be present.
      # Some web servers will reject the request if it comes too late, so let's hoist it to the top.
      if (host = datum[:headers].delete(host_key))
        datum[:headers] = { host_key => host }.merge(datum[:headers])
      end

      # default to GET if no method specified
      unless datum[:method]
        datum[:method] = :get
      end

      # if path is empty or doesn't start with '/', insert one
      unless datum[:path][0, 1] == '/'
        datum[:path] = datum[:path].dup.insert(0, '/')
      end

      if block_given?
        Excon.display_warning('Excon requests with a block are deprecated, pass :response_block instead.')
        datum[:response_block] = block
      end

      datum[:connection] = self

      # cleanup data left behind on persistent connection after interrupt
      if datum[:persistent] && !@persistent_socket_reusable
        reset
      end

      datum[:stack] = datum[:middlewares].map do |middleware|
        lambda {|stack| middleware.new(stack)}
      end.reverse.inject(self) do |middlewares, middleware|
        middleware.call(middlewares)
      end
      datum = datum[:stack].request_call(datum)

      unless datum[:pipeline]
        @persistent_socket_reusable = false
        datum = response(datum)
        @persistent_socket_reusable = true

        if datum[:persistent]
          if (key = datum[:response][:headers].keys.detect {|k| k.casecmp('Connection') == 0 })
            if datum[:response][:headers][key].casecmp('close') == 0
              reset
            end
          end
        else
          reset
        end

        Excon::Response.new(datum[:response])
      else
        datum
      end
    rescue => error
      reset

      # If we didn't get far enough to initialize datum and the middleware stack, just raise
      raise error if !datum

      datum[:error] = error
      if datum[:stack]
        datum[:stack].error_call(datum)
      else
        raise error
      end
    end

    # Sends the supplied requests to the destination host using pipelining.
    # @param pipeline_params [Array<Hash>] An array of one or more optional params, override defaults set in Connection.new, see #request for details
    def requests(pipeline_params)
      pipeline_params.each {|params| params.merge!(:pipeline => true, :persistent => true) }
      pipeline_params.last.merge!(:persistent => @data[:persistent])

      responses = pipeline_params.map do |params|
        request(params)
      end.map do |datum|
        Excon::Response.new(response(datum)[:response])
      end

      if @data[:persistent]
        if (key = responses.last[:headers].keys.detect {|k| k.casecmp('Connection') == 0 })
          if responses.last[:headers][key].casecmp('close') == 0
            reset
          end
        end
      else
        reset
      end

      responses
    end

    # Sends the supplied requests to the destination host using pipelining in
    # batches of @limit [Numeric] requests. This is your soft file descriptor
    # limit by default, typically 256.
    # @param pipeline_params [Array<Hash>] An array of one or more optional params, override defaults set in Connection.new, see #request for details
    def batch_requests(pipeline_params, limit = nil)
      limit ||= Process.respond_to?(:getrlimit) ? Process.getrlimit(:NOFILE).first : 256
      responses = []

      pipeline_params.each_slice(limit) do |params|
        responses.concat(requests(params))
      end

      responses
    end

    def reset
      if (old_socket = sockets.delete(@socket_key))
        old_socket.close rescue nil
      end
      @persistent_socket_reusable = true
    end

    # Generate HTTP request verb methods
    Excon::HTTP_VERBS.each do |method|
      class_eval <<-DEF, __FILE__, __LINE__ + 1
        def #{method}(params={}, &block)
          request(params.merge!(:method => :#{method}), &block)
        end
      DEF
    end

    def retry_limit=(new_retry_limit)
      Excon.display_warning('Excon::Connection#retry_limit= is deprecated, pass :retry_limit to the initializer.')
      @data[:retry_limit] = new_retry_limit
    end

    def retry_limit
      Excon.display_warning('Excon::Connection#retry_limit is deprecated, use Excon::Connection#data[:retry_limit].')
      @data[:retry_limit] ||= DEFAULT_RETRY_LIMIT
    end

    def inspect
      vars = instance_variables.inject({}) do |accum, var|
        accum.merge!(var.to_sym => instance_variable_get(var))
      end
      vars[:'@data'] = Utils.redact(vars[:'@data'])
      inspection = '#<Excon::Connection:'
      inspection += (object_id << 1).to_s(16)
      vars.each do |key, value|
        inspection += " #{key}=#{value.inspect}"
      end
      inspection += '>'
      inspection
    end

    def valid_request_keys(middlewares)
      valid_middleware_keys(middlewares) + Excon::VALID_REQUEST_KEYS
    end

    private

    def detect_content_length(body)
      if body.respond_to?(:size)
        # IO object: File, Tempfile, StringIO, etc.
        body.size
      elsif body.respond_to?(:stat)
        # for 1.8.7 where file does not have size
        body.stat.size
      else
        0
      end
    end

    def valid_middleware_keys(middlewares)
      middlewares.flat_map do |middleware|
        if middleware.respond_to?(:valid_parameter_keys)
          middleware.valid_parameter_keys
        else
          Excon.display_warning(
            "Excon middleware #{middleware} does not define #valid_parameter_keys"
          )
          []
        end
      end
    end

    def validate_params(validation, params, middlewares)
      valid_keys = case validation
      when :connection
        valid_middleware_keys(middlewares) + Excon::VALID_CONNECTION_KEYS
      when :request
        valid_request_keys(middlewares)
      else
        raise ArgumentError.new("Invalid validation type '#{validation}'")
      end

      invalid_keys = params.keys - valid_keys
      unless invalid_keys.empty?
        Excon.display_warning("Invalid Excon #{validation} keys: #{invalid_keys.map(&:inspect).join(', ')}")

        if validation == :request
          deprecated_keys = invalid_keys & Excon::DEPRECATED_VALID_REQUEST_KEYS.keys
          mw_msg = deprecated_keys.map do |k|
            "#{k}: #{Excon::DEPRECATED_VALID_REQUEST_KEYS[k]}"
          end.join(', ')
          Excon.display_warning(
            "The following request keys are only valid with the associated middleware: #{mw_msg}"
          )
        end
      end
    end

    def response(datum={})
      datum[:stack].response_call(datum)
    rescue => error
      case error
      when Excon::Errors::HTTPStatusError, Excon::Errors::Timeout, Excon::Errors::TooManyRedirects
        raise(error)
      else
        raise_socket_error(error)
      end
    end

    def socket(datum = @data)
      unix_proxy = datum[:proxy] ? datum[:proxy][:scheme] == UNIX : false
      sockets[@socket_key] ||= if datum[:scheme] == UNIX || unix_proxy
        Excon::UnixSocket.new(datum)
      elsif datum[:ssl_uri_schemes].include?(datum[:scheme])
        Excon::SSLSocket.new(datum)
      else
        Excon::Socket.new(datum)
      end
    end

    def sockets
      @_excon_sockets ||= {}
      @_excon_sockets.compare_by_identity

      if @pid != Process.pid
        @_excon_sockets.clear # GC will take care of closing sockets
        @pid = Process.pid
      end

      if @data[:thread_safe_sockets]
        # In a multi-threaded world, if the same connection is used by multiple
        # threads at the same time to connect to the same destination, they may
        # stomp on each other's sockets.  This ensures every thread gets their
        # own socket cache, within the context of a single connection.
        @_excon_sockets[Thread.current] ||= {}
      else
        @_excon_sockets
      end
    end

    def raise_socket_error(error)
      if error.message =~ /certificate verify failed/
        raise(Excon::Errors::CertificateError.new(error))
      else
        raise(Excon::Errors::SocketError.new(error))
      end
    end

    def proxy_match_host_port(host, port)
        host_match = if host.is_a? IPAddr
                       begin
                         host.include? @data[:host]
                       rescue IPAddr::Error
                         false
                       end
                     else
                       /(^|\.)#{host}$/.match(@data[:host])
                     end
        host_match && (port.nil? || port.to_i == @data[:port])
    end

    def proxy_from_env
      if (no_proxy_env = ENV['no_proxy'] || ENV['NO_PROXY'])
        no_proxy_list = no_proxy_env.scan(/\s*(?:\[([\dA-Fa-f:\/]+)\]|\*?\.?([^\s,:]+))(?::(\d+))?\s*/i).map { |e|
          if e[0]
            begin
              [IPAddr.new(e[0]), e[2]]
            rescue IPAddr::Error
              nil
            end
          else
            begin
              [IPAddr.new(e[1]), e[2]]
            rescue IPAddr::Error
              [e[1], e[2]]
            end
          end
        }.reject { |e| e.nil? || e[0].nil? }
      end

      unless no_proxy_env && no_proxy_list.index { |h| proxy_match_host_port(h[0], h[1]) }
        if @data[:scheme] == HTTPS && (ENV.has_key?('https_proxy') || ENV.has_key?('HTTPS_PROXY'))
          @data[:proxy] = ENV['https_proxy'] || ENV['HTTPS_PROXY']
        elsif (ENV.has_key?('http_proxy') || ENV.has_key?('HTTP_PROXY'))
          @data[:proxy] = ENV['http_proxy'] || ENV['HTTP_PROXY']
        end
      end
    end

    def setup_proxy
      if @data[:disable_proxy]
        if @data[:proxy]
          raise ArgumentError, "`:disable_proxy` parameter and `:proxy` parameter cannot both be set at the same time."
        end
        return
      end

      return if @data[:scheme] == UNIX

      proxy_from_env

      case @data[:proxy]
      when nil
        @data.delete(:proxy)
      when ''
        @data.delete(:proxy)
      when Hash
        # no processing needed
      when String, URI
        uri = @data[:proxy].is_a?(String) ? URI.parse(@data[:proxy]) : @data[:proxy]
        @data[:proxy] = {
          :host       => uri.host,
          :hostname   => uri.hostname,
          # path is only sensible for a Unix socket proxy
          :path       => uri.scheme == UNIX ? uri.path : nil,
          :port       => uri.port,
          :scheme     => uri.scheme,
        }
        if uri.password
          @data[:proxy][:password] = uri.password
        end
        if uri.user
          @data[:proxy][:user] = uri.user
        end
        if @data[:ssl_proxy_headers] && !@data[:ssl_uri_schemes].include?(@data[:scheme])
          raise ArgumentError, "The `:ssl_proxy_headers` parameter should only be used with HTTPS requests."
        end
        if @data[:proxy][:scheme] == UNIX
          # URI.parse might return empty string for security reasons.
          @data[:proxy][:host] = nil if @data[:proxy][:host] == ""
          if @data[:proxy][:host]
            raise ArgumentError, "The `:host` parameter should not be set for `unix://` proxies.\n" +
                                 "When supplying a `unix://` URI, it should start with `unix:/` or `unix:///`."
          end
        else
          unless uri.host && uri.port && uri.scheme
            raise Excon::Errors::ProxyParse, "Proxy is invalid"
          end
        end
      else
        raise Excon::Errors::ProxyParse, "Proxy is invalid"
      end

      if @data.has_key?(:proxy) && @data[:scheme] == 'http'
        @data[:headers]['Proxy-Connection'] ||= 'Keep-Alive'
        # https credentials happen in handshake
        if @data[:proxy].has_key?(:user) || @data[:proxy].has_key?(:password)
          user, pass = Utils.unescape_form(@data[:proxy][:user].to_s), Utils.unescape_form(@data[:proxy][:password].to_s)
          auth = ["#{user}:#{pass}"].pack('m').delete(Excon::CR_NL)
          @data[:headers]['Proxy-Authorization'] = 'Basic ' + auth
        end
      end
    end
  end
end
