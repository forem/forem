# frozen_string_literal: true

module Puma

  # The methods here are included in Server, but are separated into this file.
  # All the methods here pertain to passing the request to the app, then
  # writing the response back to the client.
  #
  # None of the methods here are called externally, with the exception of
  # #handle_request, which is called in Server#process_client.
  # @version 5.0.3
  #
  module Request

    include Puma::Const

    # Takes the request contained in +client+, invokes the Rack application to construct
    # the response and writes it back to +client.io+.
    #
    # It'll return +false+ when the connection is closed, this doesn't mean
    # that the response wasn't successful.
    #
    # It'll return +:async+ if the connection remains open but will be handled
    # elsewhere, i.e. the connection has been hijacked by the Rack application.
    #
    # Finally, it'll return +true+ on keep-alive connections.
    # @param client [Puma::Client]
    # @param lines [Puma::IOBuffer]
    # @param requests [Integer]
    # @return [Boolean,:async]
    #
    def handle_request(client, lines, requests)
      env = client.env
      io  = client.io   # io may be a MiniSSL::Socket

      return false if closed_socket?(io)

      normalize_env env, client

      env[PUMA_SOCKET] = io

      if env[HTTPS_KEY] && io.peercert
        env[PUMA_PEERCERT] = io.peercert
      end

      env[HIJACK_P] = true
      env[HIJACK] = client

      body = client.body

      head = env[REQUEST_METHOD] == HEAD

      env[RACK_INPUT] = body
      env[RACK_URL_SCHEME] ||= default_server_port(env) == PORT_443 ? HTTPS : HTTP

      if @early_hints
        env[EARLY_HINTS] = lambda { |headers|
          begin
            fast_write io, str_early_hints(headers)
          rescue ConnectionError => e
            @events.debug_error e
            # noop, if we lost the socket we just won't send the early hints
          end
        }
      end

      req_env_post_parse env

      # A rack extension. If the app writes #call'ables to this
      # array, we will invoke them when the request is done.
      #
      after_reply = env[RACK_AFTER_REPLY] = []

      begin
        begin
          status, headers, res_body = @thread_pool.with_force_shutdown do
            @app.call(env)
          end

          return :async if client.hijacked

          status = status.to_i

          if status == -1
            unless headers.empty? and res_body == []
              raise "async response must have empty headers and body"
            end

            return :async
          end
        rescue ThreadPool::ForceShutdown => e
          @events.unknown_error e, client, "Rack app"
          @events.log "Detected force shutdown of a thread"

          status, headers, res_body = lowlevel_error(e, env, 503)
        rescue Exception => e
          @events.unknown_error e, client, "Rack app"

          status, headers, res_body = lowlevel_error(e, env, 500)
        end

        res_info = {}
        res_info[:content_length] = nil
        res_info[:no_body] = head

        res_info[:content_length] = if res_body.kind_of? Array and res_body.size == 1
          res_body[0].bytesize
        else
          nil
        end

        cork_socket io

        str_headers(env, status, headers, res_info, lines, requests, client)

        line_ending = LINE_END

        content_length  = res_info[:content_length]
        response_hijack = res_info[:response_hijack]

        if res_info[:no_body]
          if content_length and status != 204
            lines.append CONTENT_LENGTH_S, content_length.to_s, line_ending
          end

          lines << LINE_END
          fast_write io, lines.to_s
          return res_info[:keep_alive]
        end

        if content_length
          lines.append CONTENT_LENGTH_S, content_length.to_s, line_ending
          chunked = false
        elsif !response_hijack and res_info[:allow_chunked]
          lines << TRANSFER_ENCODING_CHUNKED
          chunked = true
        end

        lines << line_ending

        fast_write io, lines.to_s

        if response_hijack
          response_hijack.call io
          return :async
        end

        begin
          res_body.each do |part|
            next if part.bytesize.zero?
            if chunked
               fast_write io, (part.bytesize.to_s(16) << line_ending)
               fast_write io, part            # part may have different encoding
               fast_write io, line_ending
            else
              fast_write io, part
            end
            io.flush
          end

          if chunked
            fast_write io, CLOSE_CHUNKED
            io.flush
          end
        rescue SystemCallError, IOError
          raise ConnectionError, "Connection error detected during write"
        end

      ensure
        begin
          uncork_socket io

          body.close
          client.tempfile.unlink if client.tempfile
        ensure
          # Whatever happens, we MUST call `close` on the response body.
          # Otherwise Rack::BodyProxy callbacks may not fire and lead to various state leaks
          res_body.close if res_body.respond_to? :close
        end

        begin
          after_reply.each { |o| o.call }
        rescue StandardError => e
          @log_writer.debug_error e
        end
      end

      res_info[:keep_alive]
    end

    # @param env [Hash] see Puma::Client#env, from request
    # @return [Puma::Const::PORT_443,Puma::Const::PORT_80]
    #
    def default_server_port(env)
      if ['on', HTTPS].include?(env[HTTPS_KEY]) || env[HTTP_X_FORWARDED_PROTO].to_s[0...5] == HTTPS || env[HTTP_X_FORWARDED_SCHEME] == HTTPS || env[HTTP_X_FORWARDED_SSL] == "on"
        PORT_443
      else
        PORT_80
      end
    end

    # Writes to an io (normally Client#io) using #syswrite
    # @param io [#syswrite] the io to write to
    # @param str [String] the string written to the io
    # @raise [ConnectionError]
    #
    def fast_write(io, str)
      n = 0
      while true
        begin
          n = io.syswrite str
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          unless io.wait_writable WRITE_TIMEOUT
            raise ConnectionError, "Socket timeout writing data"
          end

          retry
        rescue  Errno::EPIPE, SystemCallError, IOError
          raise ConnectionError, "Socket timeout writing data"
        end

        return if n == str.bytesize
        str = str.byteslice(n..-1)
      end
    end
    private :fast_write

    # @param status [Integer] status from the app
    # @return [String] the text description from Puma::HTTP_STATUS_CODES
    #
    def fetch_status_code(status)
      HTTP_STATUS_CODES.fetch(status) { 'CUSTOM' }
    end
    private :fetch_status_code

    # Given a Hash +env+ for the request read from +client+, add
    # and fixup keys to comply with Rack's env guidelines.
    # @param env [Hash] see Puma::Client#env, from request
    # @param client [Puma::Client] only needed for Client#peerip
    # @todo make private in 6.0.0
    #
    def normalize_env(env, client)
      if host = env[HTTP_HOST]
        # host can be a hostname, ipv4 or bracketed ipv6. Followed by an optional port.
        if colon = host.rindex("]:") # IPV6 with port
          env[SERVER_NAME] = host[0, colon+1]
          env[SERVER_PORT] = host[colon+2, host.bytesize]
        elsif !host.start_with?("[") && colon = host.index(":") # not hostname or IPV4 with port
          env[SERVER_NAME] = host[0, colon]
          env[SERVER_PORT] = host[colon+1, host.bytesize]
        else
          env[SERVER_NAME] = host
          env[SERVER_PORT] = default_server_port(env)
        end
      else
        env[SERVER_NAME] = LOCALHOST
        env[SERVER_PORT] = default_server_port(env)
      end

      unless env[REQUEST_PATH]
        # it might be a dumbass full host request header
        uri = URI.parse(env[REQUEST_URI])
        env[REQUEST_PATH] = uri.path

        raise "No REQUEST PATH" unless env[REQUEST_PATH]

        # A nil env value will cause a LintError (and fatal errors elsewhere),
        # so only set the env value if there actually is a value.
        env[QUERY_STRING] = uri.query if uri.query
      end

      env[PATH_INFO] = env[REQUEST_PATH]

      # From https://www.ietf.org/rfc/rfc3875 :
      # "Script authors should be aware that the REMOTE_ADDR and
      # REMOTE_HOST meta-variables (see sections 4.1.8 and 4.1.9)
      # may not identify the ultimate source of the request.
      # They identify the client for the immediate request to the
      # server; that client may be a proxy, gateway, or other
      # intermediary acting on behalf of the actual source client."
      #

      unless env.key?(REMOTE_ADDR)
        begin
          addr = client.peerip
        rescue Errno::ENOTCONN
          # Client disconnects can result in an inability to get the
          # peeraddr from the socket; default to localhost.
          addr = LOCALHOST_IP
        end

        # Set unix socket addrs to localhost
        addr = LOCALHOST_IP if addr.empty?

        env[REMOTE_ADDR] = addr
      end
    end
    # private :normalize_env

    # @param header_key [#to_s]
    # @return [Boolean]
    #
    def illegal_header_key?(header_key)
      !!(ILLEGAL_HEADER_KEY_REGEX =~ header_key.to_s)
    end

    # @param header_value [#to_s]
    # @return [Boolean]
    #
    def illegal_header_value?(header_value)
      !!(ILLEGAL_HEADER_VALUE_REGEX =~ header_value.to_s)
    end
    private :illegal_header_key?, :illegal_header_value?

    # Fixup any headers with `,` in the name to have `_` now. We emit
    # headers with `,` in them during the parse phase to avoid ambiguity
    # with the `-` to `_` conversion for critical headers. But here for
    # compatibility, we'll convert them back. This code is written to
    # avoid allocation in the common case (ie there are no headers
    # with `,` in their names), that's why it has the extra conditionals.
    #
    # @note If a normalized version of a `,` header already exists, we ignore
    #       the `,` version. This prevents clobbering headers managed by proxies
    #       but not by clients (Like X-Forwarded-For).
    #
    # @param env [Hash] see Puma::Client#env, from request, modifies in place
    # @version 5.0.3
    #
    def req_env_post_parse(env)
      to_delete = nil
      to_add = nil

      env.each do |k,v|
        if k.start_with?("HTTP_") && k.include?(",") && !UNMASKABLE_HEADERS.key?(k)
          if to_delete
            to_delete << k
          else
            to_delete = [k]
          end

          new_k = k.tr(",", "_")
          if env.key?(new_k)
            next
          end

          unless to_add
            to_add = {}
          end

          to_add[new_k] = v
        end
      end

      if to_delete # rubocop:disable Style/SafeNavigation
        to_delete.each { |k| env.delete(k) }
      end

      if to_add
        env.merge! to_add
      end
    end
    private :req_env_post_parse

    # Used in the lambda for env[ `Puma::Const::EARLY_HINTS` ]
    # @param headers [Hash] the headers returned by the Rack application
    # @return [String]
    # @version 5.0.3
    #
    def str_early_hints(headers)
      eh_str = "HTTP/1.1 103 Early Hints\r\n".dup
      headers.each_pair do |k, vs|
        next if illegal_header_key?(k)

        if vs.respond_to?(:to_s) && !vs.to_s.empty?
          vs.to_s.split(NEWLINE).each do |v|
            next if illegal_header_value?(v)
            eh_str << "#{k}: #{v}\r\n"
          end
        else
          eh_str << "#{k}: #{vs}\r\n"
        end
      end
      "#{eh_str}\r\n".freeze
    end
    private :str_early_hints

    # Processes and write headers to the IOBuffer.
    # @param env [Hash] see Puma::Client#env, from request
    # @param status [Integer] the status returned by the Rack application
    # @param headers [Hash] the headers returned by the Rack application
    # @param res_info [Hash] used to pass info between this method and #handle_request
    # @param lines [Puma::IOBuffer] modified inn place
    # @param requests [Integer] number of inline requests handled
    # @param client [Puma::Client]
    # @version 5.0.3
    #
    def str_headers(env, status, headers, res_info, lines, requests, client)
      line_ending = LINE_END
      colon = COLON

      http_11 = env[HTTP_VERSION] == HTTP_11
      if http_11
        res_info[:allow_chunked] = true
        res_info[:keep_alive] = env.fetch(HTTP_CONNECTION, "").downcase != CLOSE

        # An optimization. The most common response is 200, so we can
        # reply with the proper 200 status without having to compute
        # the response header.
        #
        if status == 200
          lines << HTTP_11_200
        else
          lines.append "HTTP/1.1 ", status.to_s, " ",
                       fetch_status_code(status), line_ending

          res_info[:no_body] ||= status < 200 || STATUS_WITH_NO_ENTITY_BODY[status]
        end
      else
        res_info[:allow_chunked] = false
        res_info[:keep_alive] = env.fetch(HTTP_CONNECTION, "").downcase == KEEP_ALIVE

        # Same optimization as above for HTTP/1.1
        #
        if status == 200
          lines << HTTP_10_200
        else
          lines.append "HTTP/1.0 ", status.to_s, " ",
                       fetch_status_code(status), line_ending

          res_info[:no_body] ||= status < 200 || STATUS_WITH_NO_ENTITY_BODY[status]
        end
      end

      # regardless of what the client wants, we always close the connection
      # if running without request queueing
      res_info[:keep_alive] &&= @queue_requests

      # Close the connection after a reasonable number of inline requests
      # if the server is at capacity and the listener has a new connection ready.
      # This allows Puma to service connections fairly when the number
      # of concurrent connections exceeds the size of the threadpool.
      res_info[:keep_alive] &&= requests < @max_fast_inline ||
        @thread_pool.busy_threads < @max_threads ||
        !client.listener.to_io.wait_readable(0)

      res_info[:response_hijack] = nil

      headers.each do |k, vs|
        next if illegal_header_key?(k)

        case k.downcase
        when CONTENT_LENGTH2
          next if illegal_header_value?(vs)
          res_info[:content_length] = vs
          next
        when TRANSFER_ENCODING
          res_info[:allow_chunked] = false
          res_info[:content_length] = nil
        when HIJACK
          res_info[:response_hijack] = vs
          next
        when BANNED_HEADER_KEY
          next
        end

        if vs.respond_to?(:to_s) && !vs.to_s.empty?
          vs.to_s.split(NEWLINE).each do |v|
            next if illegal_header_value?(v)
            lines.append k, colon, v, line_ending
          end
        else
          lines.append k, colon, line_ending
        end
      end

      # HTTP/1.1 & 1.0 assume different defaults:
      # - HTTP 1.0 assumes the connection will be closed if not specified
      # - HTTP 1.1 assumes the connection will be kept alive if not specified.
      # Only set the header if we're doing something which is not the default
      # for this protocol version
      if http_11
        lines << CONNECTION_CLOSE if !res_info[:keep_alive]
      else
        lines << CONNECTION_KEEP_ALIVE if res_info[:keep_alive]
      end
    end
    private :str_headers
  end
end
