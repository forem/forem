# frozen_string_literal: true

require "ferrum/network/exchange"
require "ferrum/network/intercepted_request"
require "ferrum/network/auth_request"
require "ferrum/network/error"
require "ferrum/network/request"
require "ferrum/network/response"

module Ferrum
  class Network
    CLEAR_TYPE = %i[traffic cache].freeze
    AUTHORIZE_TYPE = %i[server proxy].freeze
    REQUEST_STAGES = %i[Request Response].freeze
    RESOURCE_TYPES = %i[Document Stylesheet Image Media Font Script TextTrack
                        XHR Fetch Prefetch EventSource WebSocket Manifest
                        SignedExchange Ping CSPViolationReport Preflight Other].freeze
    AUTHORIZE_BLOCK_MISSING = "Block is missing, call `authorize(...) { |r| r.continue } " \
                              "or subscribe to `on(:request)` events before calling it"
    AUTHORIZE_TYPE_WRONG = ":type should be in #{AUTHORIZE_TYPE}"
    ALLOWED_CONNECTION_TYPE = %w[none cellular2g cellular3g cellular4g bluetooth ethernet wifi wimax other].freeze

    # Network traffic.
    #
    # @return [Array<Exchange>]
    #   Returns all information about network traffic as {Exchange}
    #   instance which in general is a wrapper around `request`, `response` and
    #   `error`.
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.network.traffic # => [#<Ferrum::Network::Exchange, ...]
    attr_reader :traffic

    def initialize(page)
      @page = page
      @traffic = []
      @exchange = nil
      @blacklist = nil
      @whitelist = nil
    end

    #
    # Waits for network idle or raises {Ferrum::TimeoutError} error.
    #
    # @param [Integer] connections
    #   how many connections are allowed for network to be idling,
    #
    # @param [Float] duration
    #   Sleep for given amount of time and check again.
    #
    # @param [Float] timeout
    #   During what time we try to check idle.
    #
    # @raise [Ferrum::TimeoutError]
    #
    # @example
    #   browser.go_to("https://example.com/")
    #   browser.at_xpath("//a[text() = 'No UI changes button']").click
    #   browser.network.wait_for_idle
    #
    def wait_for_idle(connections: 0, duration: 0.05, timeout: @page.browser.timeout)
      start = Utils::ElapsedTime.monotonic_time

      until idle?(connections)
        raise TimeoutError if Utils::ElapsedTime.timeout?(start, timeout)

        sleep(duration)
      end
    end

    def idle?(connections = 0)
      pending_connections <= connections
    end

    def total_connections
      @traffic.size
    end

    def finished_connections
      @traffic.count(&:finished?)
    end

    def pending_connections
      total_connections - finished_connections
    end

    #
    # Page request of the main frame.
    #
    # @return [Request]
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.network.request # => #<Ferrum::Network::Request...
    #
    def request
      @exchange&.request
    end

    #
    # Page response of the main frame.
    #
    # @return [Response, nil]
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.network.response # => #<Ferrum::Network::Response...
    #
    def response
      @exchange&.response
    end

    #
    # Contains the status code of the main page response (e.g., 200 for a
    # success). This is just a shortcut for `response.status`.
    #
    # @return [Integer, nil]
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.network.status # => 200
    #
    def status
      response&.status
    end

    #
    # Clear browser's cache or collected traffic.
    #
    # @param [:traffic, :cache] type
    #   The type of traffic to clear.
    #
    # @return [true]
    #
    # @example
    #   traffic = browser.network.traffic # => []
    #   browser.go_to("https://github.com/")
    #   traffic.size # => 51
    #   browser.network.clear(:traffic)
    #   traffic.size # => 0
    #
    def clear(type)
      raise ArgumentError, ":type should be in #{CLEAR_TYPE}" unless CLEAR_TYPE.include?(type)

      if type == :traffic
        @traffic.clear
      else
        @page.command("Network.clearBrowserCache")
      end

      true
    end

    def blacklist=(patterns)
      @blacklist = Array(patterns)
      blacklist_subscribe
    end
    alias blocklist= blacklist=

    def whitelist=(patterns)
      @whitelist = Array(patterns)
      whitelist_subscribe
    end
    alias allowlist= whitelist=

    #
    # Set request interception for given options. This method is only sets
    # request interception, you should use `on` callback to catch requests and
    # abort or continue them.
    #
    # @param [String] pattern
    #
    # @param [Symbol, nil] resource_type
    #   One of the [resource types](https://chromedevtools.github.io/devtools-protocol/tot/Network#type-ResourceType)
    #
    # @example
    #   browser = Ferrum::Browser.new
    #   browser.network.intercept
    #   browser.on(:request) do |request|
    #     if request.match?(/bla-bla/)
    #       request.abort
    #     elsif request.match?(/lorem/)
    #       request.respond(body: "Lorem ipsum")
    #     else
    #       request.continue
    #     end
    #   end
    #   browser.go_to("https://google.com")
    #
    def intercept(pattern: "*", resource_type: nil, request_stage: nil, handle_auth_requests: true)
      pattern = { urlPattern: pattern }

      if resource_type && RESOURCE_TYPES.none?(resource_type.to_sym)
        raise ArgumentError, "Unknown resource type '#{resource_type}' must be #{RESOURCE_TYPES.join(' | ')}"
      end

      if request_stage && REQUEST_STAGES.none?(request_stage.to_sym)
        raise ArgumentError, "Unknown request stage '#{request_stage}' must be #{REQUEST_STAGES.join(' | ')}"
      end

      pattern[:resourceType] = resource_type if resource_type
      pattern[:requestStage] = request_stage if request_stage
      @page.command("Fetch.enable", patterns: [pattern], handleAuthRequests: handle_auth_requests)
    end

    #
    # Sets HTTP Basic-Auth credentials.
    #
    # @param [String] user
    #   The username to send.
    #
    # @param [String] password
    #   The password to send.
    #
    # @param [:server, :proxy] type
    #   Specifies whether the credentials are for a website or a proxy.
    #
    # @yield [request]
    #   The given block will be passed each authenticated request and can allow
    #   or deny the request.
    #
    # @yieldparam [Request] request
    #   An HTTP request.
    #
    # @example
    #   browser.network.authorize(user: "login", password: "pass") { |req| req.continue }
    #   browser.go_to("http://example.com/authenticated")
    #   puts browser.network.status # => 200
    #   puts browser.body # => Welcome, authenticated client
    #
    def authorize(user:, password:, type: :server, &block)
      raise ArgumentError, AUTHORIZE_TYPE_WRONG unless AUTHORIZE_TYPE.include?(type)
      raise ArgumentError, AUTHORIZE_BLOCK_MISSING if !block_given? && !@page.subscribed?("Fetch.requestPaused")

      @authorized_ids ||= {}
      @authorized_ids[type] ||= []

      intercept

      @page.on(:request, &block)

      @page.on(:auth) do |request, index, total|
        if request.auth_challenge?(type)
          response = authorized_response(@authorized_ids[type],
                                         request.request_id,
                                         user, password)

          @authorized_ids[type] << request.request_id
          request.continue(authChallengeResponse: response)
        elsif index + 1 < total
          next # There are other callbacks that can handle this
        else
          request.abort
        end
      end
    end

    def subscribe
      subscribe_request_will_be_sent
      subscribe_response_received
      subscribe_loading_finished
      subscribe_loading_failed
      subscribe_log_entry_added
    end

    def authorized_response(ids, request_id, username, password)
      if ids.include?(request_id)
        { response: "CancelAuth" }
      elsif username && password
        { response: "ProvideCredentials",
          username: username,
          password: password }
      end
    end

    def select(request_id)
      @traffic.select { |e| e.id == request_id }
    end

    def build_exchange(id)
      Network::Exchange.new(@page, id).tap { |e| @traffic << e }
    end

    #
    # Activates emulation of network conditions.
    #
    # @param [Boolean] offline
    #   Emulate internet disconnection,
    #
    # @param [Integer] latency
    #   Minimum latency from request sent to response headers received (ms).
    #
    # @param [Integer] download_throughput
    #   Maximal aggregated download throughput (bytes/sec).
    #
    # @param [Integer] upload_throughput
    #   Maximal aggregated upload throughput (bytes/sec).
    #
    # @param [String, nil] connection_type
    #   Connection type if known:
    #   * `"none"`
    #   * `"cellular2g"`
    #   * `"cellular3g"`
    #   * `"cellular4g"`
    #   * `"bluetooth"`
    #   * `"ethernet"`
    #   * `"wifi"`
    #   * `"wimax"`
    #   * `"other"`
    #
    # @example
    #   browser.network.emulate_network_conditions(connection_type: "cellular2g")
    #   browser.go_to("https://github.com/")
    #
    def emulate_network_conditions(offline: false, latency: 0,
                                   download_throughput: -1, upload_throughput: -1,
                                   connection_type: nil)
      params = {
        offline: offline, latency: latency,
        downloadThroughput: download_throughput,
        uploadThroughput: upload_throughput
      }

      params[:connectionType] = connection_type if connection_type && ALLOWED_CONNECTION_TYPE.include?(connection_type)

      @page.command("Network.emulateNetworkConditions", **params)
      true
    end

    #
    # Activates offline mode for a page.
    #
    # @example
    #   browser.network.offline_mode
    #   browser.go_to("https://github.com/")
    #     # => Request to https://github.com/ failed (net::ERR_INTERNET_DISCONNECTED) (Ferrum::StatusError)
    #
    def offline_mode
      emulate_network_conditions(offline: true, latency: 0, download_throughput: 0, upload_throughput: 0)
    end

    #
    # Toggles ignoring cache for each request. If true, cache will not be used.
    #
    # @example
    #   browser.network.cache(disable: true)
    #
    def cache(disable:)
      @page.command("Network.setCacheDisabled", cacheDisabled: disable)
    end

    private

    def subscribe_request_will_be_sent
      @page.on("Network.requestWillBeSent") do |params|
        request = Network::Request.new(params)

        # We can build exchange in two places, here on the event or when request
        # is interrupted. So we have to be careful when to create new one. We
        # create new exchange only if there's no with such id or there's but
        # it's filled with request which means this one is new but has response
        # for a redirect. So we assign response from the params to previous
        # exchange and build new exchange to assign this request to it.
        exchange = select(request.id).last
        exchange = build_exchange(request.id) unless exchange&.blank?

        # On redirects Chrome doesn't change `requestId` and there's no
        # `Network.responseReceived` event for such request. If there's already
        # exchange object with this id then we got redirected and params has
        # `redirectResponse` key which contains the response.
        if params["redirectResponse"]
          previous_exchange = select(request.id)[-2]
          response = Network::Response.new(@page, params)
          response.loaded = true
          previous_exchange.response = response
        end

        exchange.request = request

        @exchange = exchange if exchange.navigation_request?(@page.main_frame.id)
      end
    end

    def subscribe_response_received
      @page.on("Network.responseReceived") do |params|
        exchange = select(params["requestId"]).last

        if exchange
          response = Network::Response.new(@page, params)
          exchange.response = response
        end
      end
    end

    def subscribe_loading_finished
      @page.on("Network.loadingFinished") do |params|
        response = select(params["requestId"]).last&.response

        if response
          response.loaded = true
          response.body_size = params["encodedDataLength"]
        end
      end
    end

    def subscribe_loading_failed
      @page.on("Network.loadingFailed") do |params|
        exchange = select(params["requestId"]).last
        exchange.error ||= Network::Error.new

        exchange.error.id = params["requestId"]
        exchange.error.type = params["type"]
        exchange.error.error_text = params["errorText"]
        exchange.error.monotonic_time = params["timestamp"]
        exchange.error.canceled = params["canceled"]
      end
    end

    def subscribe_log_entry_added
      @page.on("Log.entryAdded") do |params|
        entry = params["entry"] || {}
        if entry["source"] == "network" && entry["level"] == "error"
          exchange = select(entry["networkRequestId"]).last
          exchange.error ||= Network::Error.new

          exchange.error.id = entry["networkRequestId"]
          exchange.error.url = entry["url"]
          exchange.error.description = entry["text"]
          exchange.error.timestamp = entry["timestamp"]
        end
      end
    end

    def blacklist_subscribe
      return unless blacklist?
      raise ArgumentError, "You can't use blacklist along with whitelist" if whitelist?

      @blacklist_subscribe ||= begin
        intercept

        @page.on(:request) do |request|
          if @blacklist.any? { |p| request.match?(p) }
            request.abort
          else
            request.continue
          end
        end

        true
      end
    end

    def whitelist_subscribe
      return unless whitelist?
      raise ArgumentError, "You can't use whitelist along with blacklist" if blacklist?

      @whitelist_subscribe ||= begin
        intercept

        @page.on(:request) do |request|
          if @whitelist.any? { |p| request.match?(p) }
            request.continue
          else
            request.abort
          end
        end

        true
      end
    end

    def blacklist?
      Array(@blacklist).any?
    end

    def whitelist?
      Array(@whitelist).any?
    end
  end
end
