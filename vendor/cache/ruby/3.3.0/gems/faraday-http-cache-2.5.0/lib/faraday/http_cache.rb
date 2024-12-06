# frozen_string_literal: true

require 'faraday'

require 'faraday/http_cache/storage'
require 'faraday/http_cache/request'
require 'faraday/http_cache/response'
require 'faraday/http_cache/strategies'

module Faraday
  # Public: The middleware responsible for caching and serving responses.
  # The middleware use the provided configuration options to establish on of
  # 'Faraday::HttpCache::Strategies' to cache responses retrieved by the stack
  # adapter. If a stored response can be served again for a subsequent
  # request, the middleware will return the response instead of issuing a new
  # request to it's server. This middleware should be the last attached handler
  # to your stack, so it will be closest to the inner app, avoiding issues
  # with other middlewares on your stack.
  #
  # Examples:
  #
  #   # Using the middleware with a simple client:
  #   client = Faraday.new do |builder|
  #     builder.use :http_cache, store: my_store_backend
  #     builder.adapter Faraday.default_adapter
  #   end
  #
  #   # Attach a Logger to the middleware.
  #   client = Faraday.new do |builder|
  #     builder.use :http_cache, logger: my_logger_instance, store: my_store_backend
  #     builder.adapter Faraday.default_adapter
  #   end
  #
  #   # Provide an existing CacheStore (for instance, from a Rails app)
  #   client = Faraday.new do |builder|
  #     builder.use :http_cache, store: Rails.cache
  #   end
  #
  #   # Use Marshal for serialization
  #   client = Faraday.new do |builder|
  #     builder.use :http_cache, store: Rails.cache, serializer: Marshal
  #   end
  #
  #   # Instrument events using ActiveSupport::Notifications
  #   client = Faraday.new do |builder|
  #     builder.use :http_cache, store: Rails.cache, instrumenter: ActiveSupport::Notifications
  #   end
  class HttpCache < Faraday::Middleware
    UNSAFE_METHODS = %i[post put delete patch].freeze

    ERROR_STATUSES = (400..499).freeze

    # The name of the instrumentation event.
    EVENT_NAME = 'http_cache.faraday'

    CACHE_STATUSES = [
      # The request was not cacheable.
      :unacceptable,

      # The response was cached and can still be used.
      :fresh,

      # The response was cached and the server has validated it with a 304 response.
      :valid,

      # The response was cached but was not revalidated by the server.
      :invalid,

      # No response was found in the cache.
      :miss,

      # The response can't be cached.
      :uncacheable,

      # The request was cached but need to be revalidated by the server.
      :must_revalidate
    ].freeze

    # Public: Initializes a new HttpCache middleware.
    #
    # app  - the next endpoint on the 'Faraday' stack.
    # :store           - A cache store that should respond to 'read', 'write', and 'delete'.
    # :serializer      - A serializer that should respond to 'dump' and 'load'.
    # :shared_cache    - A flag to mark the middleware as a shared cache or not.
    # :instrumenter    - An instrumentation object that should respond to 'instrument'.
    # :instrument_name - The String name of the instrument being reported on (optional).
    # :logger          - A logger object.
    #
    # Examples:
    #
    #   # Initialize the middleware with a logger.
    #   Faraday::HttpCache.new(app, logger: my_logger)
    #
    #   # Initialize the middleware with a logger and Marshal as a serializer
    #   Faraday::HttpCache.new(app, logger: my_logger, serializer: Marshal)
    #
    #   # Initialize the middleware with a FileStore at the 'tmp' dir.
    #   store = ActiveSupport::Cache.lookup_store(:file_store, ['tmp'])
    #   Faraday::HttpCache.new(app, store: store)
    #
    #   # Initialize the middleware with a MemoryStore and logger
    #   store = ActiveSupport::Cache.lookup_store
    #   Faraday::HttpCache.new(app, store: store, logger: my_logger)
    def initialize(app, options = {})
      super(app)

      options = options.dup
      @logger = options[:logger]
      @shared_cache = options.delete(:shared_cache) { true }
      @instrumenter = options.delete(:instrumenter)
      @instrument_name = options.delete(:instrument_name) { EVENT_NAME }

      strategy = options.delete(:strategy) { Strategies::ByUrl }

      @strategy = strategy.new(**options)
    end

    # Public: Process the request into a duplicate of this instance to
    # ensure that the internal state is preserved.
    def call(env)
      dup.call!(env)
    end

    # Internal: Process the stack request to try to serve a cache response.
    # On a cacheable request, the middleware will attempt to locate a
    # valid stored response to serve. On a cache miss, the middleware will
    # forward the request and try to store the response for future requests.
    # If the request can't be cached, the request will be delegated directly
    # to the underlying app and does nothing to the response.
    # The processed steps will be recorded to be logged once the whole
    # process is finished.
    #
    # Returns a 'Faraday::Response' instance.
    def call!(env)
      @trace = []
      @request = create_request(env)

      response = nil

      if @request.cacheable?
        response = process(env)
      else
        trace :unacceptable
        response = @app.call(env)
      end

      response.on_complete do
        delete(@request, response) if should_delete?(response.status, @request.method)
        log_request
        response.env[:http_cache_trace] = @trace
        instrument(response.env)
      end
    end

    protected

    # Internal: Gets the request object created from the Faraday env Hash.
    attr_reader :request

    private

    # Internal: Should this cache instance act like a "shared cache" according
    # to the the definition in RFC 2616?
    def shared_cache?
      @shared_cache
    end

    # Internal: Checks if the current request method should remove any existing
    # cache entries for the same resource.
    #
    # Returns true or false.
    def should_delete?(status, method)
      UNSAFE_METHODS.include?(method) && !ERROR_STATUSES.cover?(status)
    end

    # Internal: Tries to locate a valid response or forwards the call to the stack.
    # * If no entry is present on the storage, the 'fetch' method will forward
    # the call to the remaining stack and return the new response.
    # * If a fresh response is found, the middleware will abort the remaining
    # stack calls and return the stored response back to the client.
    # * If a response is found but isn't fresh anymore, the middleware will
    # revalidate the response back to the server.
    #
    # env - the environment 'Hash' provided from the 'Faraday' stack.
    #
    # Returns the 'Faraday::Response' instance to be served.
    def process(env)
      entry = @strategy.read(@request)

      return fetch(env) if entry.nil?

      if entry.fresh? && !@request.no_cache?
        response = entry.to_response(env)
        trace :fresh
      else
        trace :must_revalidate
        response = validate(entry, env)
      end

      response
    end

    # Internal: Tries to validated a stored entry back to it's origin server
    # using the 'If-Modified-Since' and 'If-None-Match' headers with the
    # existing 'Last-Modified' and 'ETag' headers. If the new response
    # is marked as 'Not Modified', the previous stored response will be used
    # and forwarded against the Faraday stack. Otherwise, the freshly new
    # response will be stored (replacing the old one) and used.
    #
    # entry - a stale 'Faraday::HttpCache::Response' retrieved from the cache.
    # env - the environment 'Hash' to perform the request.
    #
    # Returns the 'Faraday::HttpCache::Response' to be forwarded into the stack.
    def validate(entry, env)
      headers = env[:request_headers]
      headers['If-Modified-Since'] = entry.last_modified if entry.last_modified
      headers['If-None-Match'] = entry.etag if entry.etag

      @app.call(env).on_complete do |requested_env|
        response = Response.new(requested_env)
        if response.not_modified?
          trace :valid
          updated_response_headers = response.payload[:response_headers]

          # These headers are not allowed in 304 responses, yet some proxy
          # servers add them in. Don't override the values from the original
          # response.
          updated_response_headers.delete('Content-Type')
          updated_response_headers.delete('Content-Length')

          updated_payload = entry.payload
          updated_payload[:response_headers].update(updated_response_headers)
          requested_env.update(updated_payload)
          response = Response.new(updated_payload)
        else
          trace :invalid
        end
        store(response)
      end
    end

    # Internal: Records a traced action to be used by the logger once the
    # request/response phase is finished.
    #
    # operation - the name of the performed action, a String or Symbol.
    #
    # Returns nothing.
    def trace(operation)
      @trace << operation
    end

    # Internal: Stores the response into the storage.
    # If the response isn't cacheable, a trace action 'uncacheable' will be
    # recorded for logging purposes.
    #
    # response - a 'Faraday::HttpCache::Response' instance to be stored.
    #
    # Returns nothing.
    def store(response)
      if shared_cache? ? response.cacheable_in_shared_cache? : response.cacheable_in_private_cache?
        trace :store
        @strategy.write(@request, response)
      else
        trace :uncacheable
      end
    end

    def delete(request, response)
      headers = %w[Location Content-Location]
      headers.each do |header|
        url = response.headers[header]
        @strategy.delete(url) if url
      end

      @strategy.delete(request.url)
      trace :delete
    end

    # Internal: Fetches the response from the Faraday stack and stores it.
    #
    # env - the environment 'Hash' from the Faraday stack.
    #
    # Returns the fresh 'Faraday::Response' instance.
    def fetch(env)
      trace :miss
      @app.call(env).on_complete do |fresh_env|
        response = Response.new(create_response(fresh_env))
        store(response)
      end
    end

    # Internal: Creates a new 'Hash' containing the response information.
    #
    # env - the environment 'Hash' from the Faraday stack.
    #
    # Returns a 'Hash' containing the ':status', ':body' and 'response_headers'
    # entries.
    def create_response(env)
      hash = env.to_hash

      {
        status: hash[:status],
        body: hash[:body] || hash[:response_body],
        response_headers: hash[:response_headers],
        reason_phrase: hash[:reason_phrase]
      }
    end

    def create_request(env)
      Request.from_env(env)
    end

    # Internal: Logs the trace info about the incoming request
    # and how the middleware handled it.
    # This method does nothing if theresn't a logger present.
    #
    # Returns nothing.
    def log_request
      return unless @logger

      method = @request.method.to_s.upcase
      path = @request.url.request_uri
      @logger.debug { "HTTP Cache: [#{method} #{path}] #{@trace.join(', ')}" }
    end

    # Internal: instruments the request processing.
    #
    # Returns nothing.
    def instrument(env)
      return unless @instrumenter

      payload = {
        env: env,
        cache_status: extract_status(env[:http_cache_trace])
      }

      @instrumenter.instrument(@instrument_name, payload)
      # DEPRECATED: Event name from the 1.1.1 release that isn't compatible
      # with the `ActiveSupport::LogSubscriber` API.
      @instrumenter.instrument('process_request.http_cache.faraday', payload)
    end

    # Internal: Extracts the cache status from a trace.
    #
    # Returns the Symbol status or nil if none was available.
    def extract_status(trace)
      CACHE_STATUSES.find { |status| trace.include?(status) }
    end
  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware http_cache: Faraday::HttpCache
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware http_cache: Faraday::HttpCache
end
