# frozen_string_literal: true

require "stripe/instrumentation"

module Stripe
  # StripeClient executes requests against the Stripe API and allows a user to
  # recover both a resource a call returns as well as a response object that
  # contains information on the HTTP call.
  class StripeClient
    # A set of all known thread contexts across all threads and a mutex to
    # synchronize global access to them.
    @thread_contexts_with_connection_managers = Set.new
    @thread_contexts_with_connection_managers_mutex = Mutex.new
    @last_connection_manager_gc = Util.monotonic_time

    # Initializes a new StripeClient
    def initialize(config_arg = {})
      @system_profiler = SystemProfiler.new
      @last_request_metrics = nil

      @config = case config_arg
                when Hash
                  Stripe.config.reverse_duplicate_merge(config_arg)
                when Stripe::ConnectionManager
                  # Supports accepting a connection manager object for backwards
                  # compatibility only, and that use is DEPRECATED.
                  Stripe.config.dup
                when Stripe::StripeConfiguration
                  config_arg
                when String
                  Stripe.config.reverse_duplicate_merge(
                    { api_key: config_arg }
                  )
                else
                  raise ArgumentError, "Can't handle argument: #{config_arg}"
                end
    end

    attr_reader :config
    attr_reader :options

    # Gets a currently active `StripeClient`. Set for the current thread when
    # `StripeClient#request` is being run so that API operations being executed
    # inside of that block can find the currently active client. It's reset to
    # the original value (hopefully `nil`) after the block ends.
    #
    # For internal use only. Does not provide a stable API and may be broken
    # with future non-major changes.
    def self.active_client
      current_thread_context.active_client || default_client
    end

    # Finishes any active connections by closing their TCP connection and
    # clears them from internal tracking in all connection managers across all
    # threads.
    #
    # If passed a `config` object, only clear connection managers for that
    # particular configuration.
    #
    # For internal use only. Does not provide a stable API and may be broken
    # with future non-major changes.
    def self.clear_all_connection_managers(config: nil)
      # Just a quick path for when configuration is being set for the first
      # time before any connections have been opened. There is technically some
      # potential for thread raciness here, but not in a practical sense.
      return if @thread_contexts_with_connection_managers.empty?

      @thread_contexts_with_connection_managers_mutex.synchronize do
        pruned_contexts = Set.new

        @thread_contexts_with_connection_managers.each do |thread_context|
          # Note that the thread context itself is not destroyed, but we clear
          # its connection manager and remove our reference to it. If it ever
          # makes a new request we'll give it a new connection manager and
          # it'll go back into `@thread_contexts_with_connection_managers`.
          thread_context.default_connection_managers.reject! do |cm_config, cm|
            if config.nil? || config.key == cm_config
              cm.clear
              true
            end
          end

          if thread_context.default_connection_managers.empty?
            pruned_contexts << thread_context
          end
        end

        @thread_contexts_with_connection_managers.subtract(pruned_contexts)
      end
    end

    # A default client for the current thread.
    def self.default_client
      current_thread_context.default_client ||= StripeClient.new(Stripe.config)
    end

    # A default connection manager for the current thread scoped to the
    # configuration object that may be provided.
    def self.default_connection_manager(config = Stripe.config)
      current_thread_context.default_connection_managers[config.key] ||= begin
        connection_manager = ConnectionManager.new(config)

        @thread_contexts_with_connection_managers_mutex.synchronize do
          maybe_gc_connection_managers
          @thread_contexts_with_connection_managers << current_thread_context
        end

        connection_manager
      end
    end

    # Checks if an error is a problem that we should retry on. This includes
    # both socket errors that may represent an intermittent problem and some
    # special HTTP statuses.
    def self.should_retry?(error,
                           method:, num_retries:, config: Stripe.config)
      return false if num_retries >= config.max_network_retries

      case error
      when Net::OpenTimeout, Net::ReadTimeout
        # Retry on timeout-related problems (either on open or read).
        true
      when EOFError, Errno::ECONNREFUSED, Errno::ECONNRESET,
            Errno::EHOSTUNREACH, Errno::ETIMEDOUT, SocketError
        # Destination refused the connection, the connection was reset, or a
        # variety of other connection failures. This could occur from a single
        # saturated server, so retry in case it's intermittent.
        true
      when Stripe::StripeError
        # The API may ask us not to retry (e.g. if doing so would be a no-op),
        # or advise us to retry (e.g. in cases of lock timeouts). Defer to
        # those instructions if given.
        return false if error.http_headers["stripe-should-retry"] == "false"
        return true if error.http_headers["stripe-should-retry"] == "true"

        # 409 Conflict
        return true if error.http_status == 409

        # 429 Too Many Requests
        #
        # There are a few different problems that can lead to a 429. The most
        # common is rate limiting, on which we *don't* want to retry because
        # that'd likely contribute to more contention problems. However, some
        # 429s are lock timeouts, which is when a request conflicted with
        # another request or an internal process on some particular object.
        # These 429s are safe to retry.
        return true if error.http_status == 429 && error.code == "lock_timeout"

        # 500 Internal Server Error
        #
        # We only bother retrying these for non-POST requests. POSTs end up
        # being cached by the idempotency layer so there's no purpose in
        # retrying them.
        return true if error.http_status == 500 && method != :post

        # 503 Service Unavailable
        error.http_status == 503
      else
        false
      end
    end

    def self.sleep_time(num_retries, config: Stripe.config)
      # Apply exponential backoff with initial_network_retry_delay on the
      # number of num_retries so far as inputs. Do not allow the number to
      # exceed max_network_retry_delay.
      sleep_seconds = [
        config.initial_network_retry_delay * (2**(num_retries - 1)),
        config.max_network_retry_delay,
      ].min

      # Apply some jitter by randomizing the value in the range of
      # (sleep_seconds / 2) to (sleep_seconds).
      sleep_seconds *= (0.5 * (1 + rand))

      # But never sleep less than the base sleep seconds.
      [config.initial_network_retry_delay, sleep_seconds].max
    end

    # Gets the connection manager in use for the current `StripeClient`.
    #
    # This method is DEPRECATED and for backwards compatibility only.
    def connection_manager
      self.class.default_connection_manager
    end
    extend Gem::Deprecate
    deprecate :connection_manager, :none, 2020, 9

    # Executes the API call within the given block. Usage looks like:
    #
    #     client = StripeClient.new
    #     charge, resp = client.request { Charge.create }
    #
    def request
      old_stripe_client = self.class.current_thread_context.active_client
      self.class.current_thread_context.active_client = self

      if self.class.current_thread_context.last_responses&.key?(object_id)
        raise "calls to StripeClient#request cannot be nested within a thread"
      end

      self.class.current_thread_context.last_responses ||= {}
      self.class.current_thread_context.last_responses[object_id] = nil

      begin
        res = yield
        [res, self.class.current_thread_context.last_responses[object_id]]
      ensure
        self.class.current_thread_context.active_client = old_stripe_client
        self.class.current_thread_context.last_responses.delete(object_id)
      end
    end

    def execute_request(method, path,
                        api_base: nil, api_key: nil, headers: {}, params: {})
      http_resp, api_key = execute_request_internal(
        method, path, api_base, api_key, headers, params
      )

      begin
        resp = StripeResponse.from_net_http(http_resp)
      rescue JSON::ParserError
        raise general_api_error(http_resp.code.to_i, http_resp.body)
      end

      # If being called from `StripeClient#request`, put the last response in
      # thread-local memory so that it can be returned to the user. Don't store
      # anything otherwise so that we don't leak memory.
      store_last_response(object_id, resp)

      [resp, api_key]
    end

    # Executes a request and returns the body as a stream instead of converting
    # it to a StripeObject. This should be used for any request where we expect
    # an arbitrary binary response.
    #
    # A `read_body_chunk` block can be passed, which will be called repeatedly
    # with the body chunks read from the socket.
    #
    # If a block is passed, a StripeHeadersOnlyResponse is returned as the
    # block is expected to do all the necessary body processing. If no block is
    # passed, then a StripeStreamResponse is returned containing an IO stream
    # with the response body.
    def execute_request_stream(method, path,
                               api_base: nil, api_key: nil,
                               headers: {}, params: {},
                               &read_body_chunk_block)
      unless block_given?
        raise ArgumentError,
              "execute_request_stream requires a read_body_chunk_block"
      end

      http_resp, api_key = execute_request_internal(
        method, path, api_base, api_key, headers, params, &read_body_chunk_block
      )

      # When the read_body_chunk_block is given, we no longer have access to the
      # response body at this point and so return a response object containing
      # only the headers. This is because the body was consumed by the block.
      resp = StripeHeadersOnlyResponse.from_net_http(http_resp)

      [resp, api_key]
    end

    def store_last_response(object_id, resp)
      return unless last_response_has_key?(object_id)

      self.class.current_thread_context.last_responses[object_id] = resp
    end

    def last_response_has_key?(object_id)
      self.class.current_thread_context.last_responses&.key?(object_id)
    end

    #
    # private
    #

    # Time (in seconds) that a connection manager has not been used before it's
    # eligible for garbage collection.
    CONNECTION_MANAGER_GC_LAST_USED_EXPIRY = 120

    # How often to check (in seconds) for connection managers that haven't been
    # used in a long time and which should be garbage collected.
    CONNECTION_MANAGER_GC_PERIOD = 60

    ERROR_MESSAGE_CONNECTION =
      "Unexpected error communicating when trying to connect to " \
        "Stripe (%s). You may be seeing this message because your DNS is not " \
        "working or you don't have an internet connection.  To check, try " \
        "running `host stripe.com` from the command line."
    ERROR_MESSAGE_SSL =
      "Could not establish a secure connection to Stripe (%s), you " \
        "may need to upgrade your OpenSSL version. To check, try running " \
        "`openssl s_client -connect api.stripe.com:443` from the command " \
        "line."

    # Common error suffix sared by both connect and read timeout messages.
    ERROR_MESSAGE_TIMEOUT_SUFFIX =
      "Please check your internet connection and try again. " \
        "If this problem persists, you should check Stripe's service " \
        "status at https://status.stripe.com, or let us know at " \
        "support@stripe.com."

    ERROR_MESSAGE_TIMEOUT_CONNECT = (
      "Timed out connecting to Stripe (%s). " +
      ERROR_MESSAGE_TIMEOUT_SUFFIX
    ).freeze

    ERROR_MESSAGE_TIMEOUT_READ = (
      "Timed out communicating with Stripe (%s). " +
      ERROR_MESSAGE_TIMEOUT_SUFFIX
    ).freeze

    # Maps types of exceptions that we're likely to see during a network
    # request to more user-friendly messages that we put in front of people.
    # The original error message is also appended onto the final exception for
    # full transparency.
    NETWORK_ERROR_MESSAGES_MAP = {
      EOFError => ERROR_MESSAGE_CONNECTION,
      Errno::ECONNREFUSED => ERROR_MESSAGE_CONNECTION,
      Errno::ECONNRESET => ERROR_MESSAGE_CONNECTION,
      Errno::EHOSTUNREACH => ERROR_MESSAGE_CONNECTION,
      Errno::ETIMEDOUT => ERROR_MESSAGE_TIMEOUT_CONNECT,
      SocketError => ERROR_MESSAGE_CONNECTION,

      Net::OpenTimeout => ERROR_MESSAGE_TIMEOUT_CONNECT,
      Net::ReadTimeout => ERROR_MESSAGE_TIMEOUT_READ,

      OpenSSL::SSL::SSLError => ERROR_MESSAGE_SSL,
    }.freeze
    private_constant :NETWORK_ERROR_MESSAGES_MAP

    # A record representing any data that `StripeClient` puts into
    # `Thread.current`. Making it a class likes this gives us a little extra
    # type safety and lets us document what each field does.
    #
    # For internal use only. Does not provide a stable API and may be broken
    # with future non-major changes.
    class ThreadContext
      # A `StripeClient` that's been flagged as currently active within a
      # thread by `StripeClient#request`. A client stays active until the
      # completion of the request block.
      attr_accessor :active_client

      # A default `StripeClient` object for the thread. Used in all cases where
      # the user hasn't specified their own.
      attr_accessor :default_client

      # A temporary map of object IDs to responses from last executed API
      # calls. Used to return a responses from calls to `StripeClient#request`.
      #
      # Stored in the thread data to make the use of a single `StripeClient`
      # object safe across multiple threads. Stored as a map so that multiple
      # `StripeClient` objects can run concurrently on the same thread.
      #
      # Responses are only left in as long as they're needed, which means
      # they're removed as soon as a call leaves `StripeClient#request`, and
      # because that's wrapped in an `ensure` block, they should never leave
      # garbage in `Thread.current`.
      attr_accessor :last_responses

      # A map of connection mangers for the thread. Normally shared between
      # all `StripeClient` objects on a particular thread, and created so as to
      # minimize the number of open connections that an application needs.
      def default_connection_managers
        @default_connection_managers ||= {}
      end

      def reset_connection_managers
        @default_connection_managers = {}
      end
    end

    # Access data stored for `StripeClient` within the thread's current
    # context. Returns `ThreadContext`.
    #
    # For internal use only. Does not provide a stable API and may be broken
    # with future non-major changes.
    def self.current_thread_context
      Thread.current[:stripe_client__internal_use_only] ||= ThreadContext.new
    end

    # Garbage collects connection managers that haven't been used in some time,
    # with the idea being that we want to remove old connection managers that
    # belong to dead threads and the like.
    #
    # Prefixed with `maybe_` because garbage collection will only run
    # periodically so that we're not constantly engaged in busy work. If
    # connection managers live a little passed their useful age it's not
    # harmful, so it's not necessary to get them right away.
    #
    # For testability, returns `nil` if it didn't run and the number of
    # connection managers that were garbage collected otherwise.
    #
    # IMPORTANT: This method is not thread-safe and expects to be called inside
    # a lock on `@thread_contexts_with_connection_managers_mutex`.
    #
    # For internal use only. Does not provide a stable API and may be broken
    # with future non-major changes.
    def self.maybe_gc_connection_managers
      next_gc_time = @last_connection_manager_gc + CONNECTION_MANAGER_GC_PERIOD
      return nil if next_gc_time > Util.monotonic_time

      last_used_threshold =
        Util.monotonic_time - CONNECTION_MANAGER_GC_LAST_USED_EXPIRY

      pruned_contexts = []
      @thread_contexts_with_connection_managers.each do |thread_context|
        thread_context
          .default_connection_managers
          .each do |config_key, connection_manager|
            next if connection_manager.last_used > last_used_threshold

            connection_manager.clear
            thread_context.default_connection_managers.delete(config_key)
          end
      end

      @thread_contexts_with_connection_managers.each do |thread_context|
        next unless thread_context.default_connection_managers.empty?

        pruned_contexts << thread_context
      end

      @thread_contexts_with_connection_managers -= pruned_contexts
      @last_connection_manager_gc = Util.monotonic_time

      pruned_contexts.count
    end

    private def execute_request_internal(method, path,
                                         api_base, api_key, headers, params,
                                         &read_body_chunk_block)
      raise ArgumentError, "method should be a symbol" \
      unless method.is_a?(Symbol)
      raise ArgumentError, "path should be a string" \
      unless path.is_a?(String)

      api_base ||= config.api_base
      api_key ||= config.api_key
      params = Util.objects_to_ids(params)

      check_api_key!(api_key)

      body_params = nil
      query_params = nil
      case method
      when :get, :head, :delete
        query_params = params
      else
        body_params = params
      end

      query_params, path = merge_query_params(query_params, path)

      headers = request_headers(api_key, method)
                .update(Util.normalize_headers(headers))
      url = api_url(path, api_base)

      # Merge given query parameters with any already encoded in the path.
      query = query_params ? Util.encode_parameters(query_params) : nil

      # Encoding body parameters is a little more complex because we may have
      # to send a multipart-encoded body. `body_log` is produced separately as
      # a log-friendly variant of the encoded form. File objects are displayed
      # as such instead of as their file contents.
      body, body_log =
        body_params ? encode_body(body_params, headers) : [nil, nil]

      # stores information on the request we're about to make so that we don't
      # have to pass as many parameters around for logging.
      context = RequestLogContext.new
      context.account         = headers["Stripe-Account"]
      context.api_key         = api_key
      context.api_version     = headers["Stripe-Version"]
      context.body            = body_log
      context.idempotency_key = headers["Idempotency-Key"]
      context.method          = method
      context.path            = path
      context.query           = query

      # A block can be passed in to read the content directly from the response.
      # We want to execute this block only when the response was actually
      # successful. When it wasn't, we defer to the standard error handling as
      # we have to read the body and parse the error JSON.
      response_block =
        if block_given?
          lambda do |response|
            unless should_handle_as_error(response.code.to_i)
              response.read_body(&read_body_chunk_block)
            end
          end
        end

      http_resp = execute_request_with_rescues(method, api_base, context) do
        self.class
            .default_connection_manager(config)
            .execute_request(method, url,
                             body: body,
                             headers: headers,
                             query: query,
                             &response_block)
      end

      [http_resp, api_key]
    end

    private def api_url(url = "", api_base = nil)
      (api_base || config.api_base) + url
    end

    private def check_api_key!(api_key)
      unless api_key
        raise AuthenticationError, "No API key provided. " \
          'Set your API key using "Stripe.api_key = <API-KEY>". ' \
          "You can generate API keys from the Stripe web interface. " \
          "See https://stripe.com/api for details, or email " \
          "support@stripe.com if you have any questions."
      end

      return unless api_key =~ /\s/

      raise AuthenticationError, "Your API key is invalid, as it contains " \
        "whitespace. (HINT: You can double-check your API key from the " \
        "Stripe web interface. See https://stripe.com/api for details, or " \
        "email support@stripe.com if you have any questions.)"
    end

    # Encodes a set of body parameters using multipart if `Content-Type` is set
    # for that, or standard form-encoding otherwise. Returns the encoded body
    # and a version of the encoded body that's safe to be logged.
    private def encode_body(body_params, headers)
      body = nil
      flattened_params = Util.flatten_params(body_params)

      if headers["Content-Type"] == MultipartEncoder::MULTIPART_FORM_DATA
        body, content_type = MultipartEncoder.encode(flattened_params)

        # Set a new content type that also includes the multipart boundary.
        # See `MultipartEncoder` for details.
        headers["Content-Type"] = content_type

        # `#to_s` any complex objects like files and the like to build output
        # that's more condusive to logging.
        flattened_params =
          flattened_params.map { |k, v| [k, v.is_a?(String) ? v : v.to_s] }.to_h

      else
        body = Util.encode_parameters(body_params)
      end

      # We don't use `Util.encode_parameters` partly as an optimization (to not
      # redo work we've already done), and partly because the encoded forms of
      # certain characters introduce a lot of visual noise and it's nice to
      # have a clearer format for logs.
      body_log = flattened_params.map { |k, v| "#{k}=#{v}" }.join("&")

      [body, body_log]
    end

    private def should_handle_as_error(http_status)
      http_status >= 400
    end

    private def execute_request_with_rescues(method, api_base, context)
      num_retries = 0

      begin
        request_start = nil
        user_data = nil

        log_request(context, num_retries)
        user_data = notify_request_begin(context)

        request_start = Util.monotonic_time
        resp = yield
        request_duration = Util.monotonic_time - request_start

        http_status = resp.code.to_i
        context = context.dup_from_response_headers(resp)

        if should_handle_as_error(http_status)
          handle_error_response(resp, context)
        end

        log_response(context, request_start, http_status, resp.body, resp)
        notify_request_end(context, request_duration, http_status,
                           num_retries, user_data)

        if config.enable_telemetry? && context.request_id
          request_duration_ms = (request_duration * 1000).to_i
          @last_request_metrics =
            StripeRequestMetrics.new(context.request_id, request_duration_ms)
        end

      # We rescue all exceptions from a request so that we have an easy spot to
      # implement our retry logic across the board. We'll re-raise if it's a
      # type of exception that we didn't expect to handle.
      rescue StandardError => e
        # If we modify context we copy it into a new variable so as not to
        # taint the original on a retry.
        error_context = context
        http_status = nil
        request_duration = Util.monotonic_time - request_start if request_start

        if e.is_a?(Stripe::StripeError)
          error_context = context.dup_from_response_headers(e.http_headers)
          http_status = resp.code.to_i
          log_response(error_context, request_start,
                       e.http_status, e.http_body, resp)
        else
          log_response_error(error_context, request_start, e)
        end
        notify_request_end(context, request_duration, http_status, num_retries,
                           user_data)

        if self.class.should_retry?(e,
                                    method: method,
                                    num_retries: num_retries,
                                    config: config)
          num_retries += 1
          sleep self.class.sleep_time(num_retries, config: config)
          retry
        end

        case e
        when Stripe::StripeError
          raise
        when *NETWORK_ERROR_MESSAGES_MAP.keys
          handle_network_error(e, error_context, num_retries, api_base)

        # Only handle errors when we know we can do so, and re-raise otherwise.
        # This should be pretty infrequent.
        else
          raise
        end
      end

      resp
    end

    private def notify_request_begin(context)
      return unless Instrumentation.any_subscribers?(:request_begin)

      event = Instrumentation::RequestBeginEvent.new(
        method: context.method,
        path: context.path,
        user_data: {}
      )
      Stripe::Instrumentation.notify(:request_begin, event)

      # This field may be set in the `request_begin` callback. If so, we'll
      # forward it onto `request_end`.
      event.user_data
    end

    private def notify_request_end(context, duration, http_status, num_retries,
                                   user_data)
      return if !Instrumentation.any_subscribers?(:request_end) &&
                !Instrumentation.any_subscribers?(:request)

      event = Instrumentation::RequestEndEvent.new(
        duration: duration,
        http_status: http_status,
        method: context.method,
        num_retries: num_retries,
        path: context.path,
        request_id: context.request_id,
        user_data: user_data || {}
      )
      Stripe::Instrumentation.notify(:request_end, event)

      # The name before `request_begin` was also added. Provided for backwards
      # compatibility.
      Stripe::Instrumentation.notify(:request, event)
    end

    private def general_api_error(status, body)
      APIError.new("Invalid response object from API: #{body.inspect} " \
                   "(HTTP response code was #{status})",
                   http_status: status, http_body: body)
    end

    # Formats a plugin "app info" hash into a string that we can tack onto the
    # end of a User-Agent string where it'll be fairly prominent in places like
    # the Dashboard. Note that this formatting has been implemented to match
    # other libraries, and shouldn't be changed without universal consensus.
    private def format_app_info(info)
      str = info[:name]
      str = "#{str}/#{info[:version]}" unless info[:version].nil?
      str = "#{str} (#{info[:url]})" unless info[:url].nil?
      str
    end

    private def handle_error_response(http_resp, context)
      begin
        resp = StripeResponse.from_net_http(http_resp)
        error_data = resp.data[:error]

        raise StripeError, "Indeterminate error" unless error_data
      rescue JSON::ParserError, StripeError
        raise general_api_error(http_resp.code.to_i, http_resp.body)
      end

      error = if error_data.is_a?(String)
                specific_oauth_error(resp, error_data, context)
              else
                specific_api_error(resp, error_data, context)
              end

      error.response = resp
      raise(error)
    end

    # Works around an edge case where we end up with both query parameters from
    # parameteers and query parameters that were appended onto the end of the
    # given path.
    #
    # Decode any parameters that were added onto the end of a path and add them
    # to a unified query parameter hash so that all parameters end up in one
    # place and all of them are correctly included in the final request.
    private def merge_query_params(query_params, path)
      u = URI.parse(path)

      # Return original results if there was nothing to be found.
      return query_params, path if u.query.nil?

      query_params ||= {}
      query_params = Hash[URI.decode_www_form(u.query)].merge(query_params)

      # Reset the path minus any query parameters that were specified.
      path = u.path

      [query_params, path]
    end

    private def specific_api_error(resp, error_data, context)
      Util.log_error("Stripe API error",
                     status: resp.http_status,
                     error_code: error_data[:code],
                     error_message: error_data[:message],
                     error_param: error_data[:param],
                     error_type: error_data[:type],
                     idempotency_key: context.idempotency_key,
                     request_id: context.request_id,
                     config: config)

      # The standard set of arguments that can be used to initialize most of
      # the exceptions.
      opts = {
        http_body: resp.http_body,
        http_headers: resp.http_headers,
        http_status: resp.http_status,
        json_body: resp.data,
        code: error_data[:code],
      }

      case resp.http_status
      when 400, 404
        case error_data[:type]
        when "idempotency_error"
          IdempotencyError.new(error_data[:message], **opts)
        else
          InvalidRequestError.new(
            error_data[:message], error_data[:param],
            **opts
          )
        end
      when 401
        AuthenticationError.new(error_data[:message], **opts)
      when 402
        CardError.new(
          error_data[:message], error_data[:param],
          **opts
        )
      when 403
        PermissionError.new(error_data[:message], **opts)
      when 429
        RateLimitError.new(error_data[:message], **opts)
      else
        APIError.new(error_data[:message], **opts)
      end
    end

    # Attempts to look at a response's error code and return an OAuth error if
    # one matches. Will return `nil` if the code isn't recognized.
    private def specific_oauth_error(resp, error_code, context)
      description = resp.data[:error_description] || error_code

      Util.log_error("Stripe OAuth error",
                     status: resp.http_status,
                     error_code: error_code,
                     error_description: description,
                     idempotency_key: context.idempotency_key,
                     request_id: context.request_id,
                     config: config)

      args = {
        http_status: resp.http_status, http_body: resp.http_body,
        json_body: resp.data, http_headers: resp.http_headers,
      }

      case error_code
      when "invalid_client"
        OAuth::InvalidClientError.new(error_code, description, **args)
      when "invalid_grant"
        OAuth::InvalidGrantError.new(error_code, description, **args)
      when "invalid_request"
        OAuth::InvalidRequestError.new(error_code, description, **args)
      when "invalid_scope"
        OAuth::InvalidScopeError.new(error_code, description, **args)
      when "unsupported_grant_type"
        OAuth::UnsupportedGrantTypeError.new(error_code, description, **args)
      when "unsupported_response_type"
        OAuth::UnsupportedResponseTypeError.new(error_code, description, **args)
      else
        # We'd prefer that all errors are typed, but we create a generic
        # OAuthError in case we run into a code that we don't recognize.
        OAuth::OAuthError.new(error_code, description, **args)
      end
    end

    private def handle_network_error(error, context, num_retries,
                                     api_base = nil)
      Util.log_error("Stripe network error",
                     error_message: error.message,
                     idempotency_key: context.idempotency_key,
                     request_id: context.request_id,
                     config: config)

      errors, message = NETWORK_ERROR_MESSAGES_MAP.detect do |(e, _)|
        error.is_a?(e)
      end

      if errors.nil?
        message = "Unexpected error #{error.class.name} communicating " \
          "with Stripe. Please let us know at support@stripe.com."
      end

      api_base ||= config.api_base
      message = message % api_base

      message += " Request was retried #{num_retries} times." if num_retries > 0

      raise APIConnectionError,
            message + "\n\n(Network error: #{error.message})"
    end

    private def request_headers(api_key, method)
      user_agent = "Stripe/v1 RubyBindings/#{Stripe::VERSION}"
      unless Stripe.app_info.nil?
        user_agent += " " + format_app_info(Stripe.app_info)
      end

      headers = {
        "User-Agent" => user_agent,
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/x-www-form-urlencoded",
      }

      if config.enable_telemetry? && !@last_request_metrics.nil?
        headers["X-Stripe-Client-Telemetry"] = JSON.generate(
          last_request_metrics: @last_request_metrics.payload
        )
      end

      # It is only safe to retry network failures on post and delete
      # requests if we add an Idempotency-Key header
      if %i[post delete].include?(method) && config.max_network_retries > 0
        headers["Idempotency-Key"] ||= SecureRandom.uuid
      end

      headers["Stripe-Version"] = config.api_version if config.api_version
      headers["Stripe-Account"] = config.stripe_account if config.stripe_account

      user_agent = @system_profiler.user_agent
      begin
        headers.update(
          "X-Stripe-Client-User-Agent" => JSON.generate(user_agent)
        )
      rescue StandardError => e
        headers.update(
          "X-Stripe-Client-Raw-User-Agent" => user_agent.inspect,
          :error => "#{e} (#{e.class})"
        )
      end

      headers
    end

    private def log_request(context, num_retries)
      Util.log_info("Request to Stripe API",
                    account: context.account,
                    api_version: context.api_version,
                    idempotency_key: context.idempotency_key,
                    method: context.method,
                    num_retries: num_retries,
                    path: context.path,
                    config: config)
      Util.log_debug("Request details",
                     body: context.body,
                     idempotency_key: context.idempotency_key,
                     query: context.query,
                     config: config,
                     process_id: Process.pid,
                     thread_object_id: Thread.current.object_id,
                     log_timestamp: Util.monotonic_time)
    end

    private def log_response(context, request_start, status, body, resp)
      Util.log_info("Response from Stripe API",
                    account: context.account,
                    api_version: context.api_version,
                    elapsed: Util.monotonic_time - request_start,
                    idempotency_key: context.idempotency_key,
                    method: context.method,
                    path: context.path,
                    request_id: context.request_id,
                    status: status,
                    config: config)
      Util.log_debug("Response details",
                     body: body,
                     idempotency_key: context.idempotency_key,
                     request_id: context.request_id,
                     config: config,
                     process_id: Process.pid,
                     thread_object_id: Thread.current.object_id,
                     response_object_id: resp.object_id,
                     log_timestamp: Util.monotonic_time)

      return unless context.request_id

      Util.log_debug("Dashboard link for request",
                     idempotency_key: context.idempotency_key,
                     request_id: context.request_id,
                     url: Util.request_id_dashboard_url(context.request_id,
                                                        context.api_key),
                     config: config)
    end

    private def log_response_error(context, request_start, error)
      elapsed = request_start ? Util.monotonic_time - request_start : nil
      Util.log_error("Request error",
                     elapsed: elapsed,
                     error_message: error.message,
                     idempotency_key: context.idempotency_key,
                     method: context.method,
                     path: context.path,
                     config: config)
    end

    # RequestLogContext stores information about a request that's begin made so
    # that we can log certain information. It's useful because it means that we
    # don't have to pass around as many parameters.
    class RequestLogContext
      attr_accessor :body
      attr_accessor :account
      attr_accessor :api_key
      attr_accessor :api_version
      attr_accessor :idempotency_key
      attr_accessor :method
      attr_accessor :path
      attr_accessor :query
      attr_accessor :request_id

      # The idea with this method is that we might want to update some of
      # context information because a response that we've received from the API
      # contains information that's more authoritative than what we started
      # with for a request. For example, we should trust whatever came back in
      # a `Stripe-Version` header beyond what configuration information that we
      # might have had available.
      def dup_from_response_headers(headers)
        context = dup
        context.account = headers["Stripe-Account"]
        context.api_version = headers["Stripe-Version"]
        context.idempotency_key = headers["Idempotency-Key"]
        context.request_id = headers["Request-Id"]
        context
      end
    end

    # SystemProfiler extracts information about the system that we're running
    # in so that we can generate a rich user agent header to help debug
    # integrations.
    class SystemProfiler
      def self.uname
        if ::File.exist?("/proc/version")
          ::File.read("/proc/version").strip
        else
          case RbConfig::CONFIG["host_os"]
          when /linux|darwin|bsd|sunos|solaris|cygwin/i
            uname_from_system
          when /mswin|mingw/i
            uname_from_system_ver
          else
            "unknown platform"
          end
        end
      end

      def self.uname_from_system
        (`uname -a 2>/dev/null` || "").strip
      rescue Errno::ENOENT
        "uname executable not found"
      rescue Errno::ENOMEM # couldn't create subprocess
        "uname lookup failed"
      end

      def self.uname_from_system_ver
        (`ver` || "").strip
      rescue Errno::ENOENT
        "ver executable not found"
      rescue Errno::ENOMEM # couldn't create subprocess
        "uname lookup failed"
      end

      def initialize
        @uname = self.class.uname
      end

      def user_agent
        lang_version = "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} " \
                       "(#{RUBY_RELEASE_DATE})"

        {
          application: Stripe.app_info,
          bindings_version: Stripe::VERSION,
          lang: "ruby",
          lang_version: lang_version,
          platform: RUBY_PLATFORM,
          engine: defined?(RUBY_ENGINE) ? RUBY_ENGINE : "",
          publisher: "stripe",
          uname: @uname,
          hostname: Socket.gethostname,
        }.delete_if { |_k, v| v.nil? }
      end
    end

    # StripeRequestMetrics tracks metadata to be reported to stripe for metrics
    # collection
    class StripeRequestMetrics
      # The Stripe request ID of the response.
      attr_accessor :request_id

      # Request duration in milliseconds
      attr_accessor :request_duration_ms

      def initialize(request_id, request_duration_ms)
        self.request_id = request_id
        self.request_duration_ms = request_duration_ms
      end

      def payload
        { request_id: request_id, request_duration_ms: request_duration_ms }
      end
    end
  end
end
