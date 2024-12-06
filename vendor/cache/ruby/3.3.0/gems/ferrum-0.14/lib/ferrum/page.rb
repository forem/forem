# frozen_string_literal: true

require "forwardable"
require "ferrum/mouse"
require "ferrum/keyboard"
require "ferrum/headers"
require "ferrum/cookies"
require "ferrum/dialog"
require "ferrum/network"
require "ferrum/page/frames"
require "ferrum/page/screenshot"
require "ferrum/page/animation"
require "ferrum/page/tracing"
require "ferrum/page/stream"
require "ferrum/browser/client"

module Ferrum
  class Page
    GOTO_WAIT = ENV.fetch("FERRUM_GOTO_WAIT", 0.1).to_f

    class Event < Concurrent::Event
      def iteration
        synchronize { @iteration }
      end

      def reset
        synchronize do
          @iteration += 1
          @set = false if @set
          @iteration
        end
      end
    end

    extend Forwardable
    delegate %i[at_css at_xpath css xpath
                current_url current_title url title body doctype content=
                execution_id execution_id! evaluate evaluate_on evaluate_async execute evaluate_func
                add_script_tag add_style_tag] => :main_frame

    include Animation
    include Screenshot
    include Frames
    include Stream

    attr_accessor :referrer, :timeout
    attr_reader :target_id, :browser, :event, :tracing

    # Mouse object.
    #
    # @return [Mouse]
    attr_reader :mouse

    # Keyboard object.
    #
    # @return [Keyboard]
    attr_reader :keyboard

    # Network object.
    #
    # @return [Network]
    attr_reader :network

    # Headers object.
    #
    # @return [Headers]
    attr_reader :headers

    # Cookie store.
    #
    # @return [Cookies]
    attr_reader :cookies

    def initialize(target_id, browser, proxy: nil)
      @frames = Concurrent::Map.new
      @main_frame = Frame.new(nil, self)
      @browser = browser
      @target_id = target_id
      @timeout = @browser.timeout
      @event = Event.new.tap(&:set)
      self.proxy = proxy

      @client = Browser::Client.new(ws_url, self,
                                    logger: @browser.options.logger,
                                    ws_max_receive_size: @browser.options.ws_max_receive_size,
                                    id_starts_with: 1000)

      @mouse = Mouse.new(self)
      @keyboard = Keyboard.new(self)
      @headers = Headers.new(self)
      @cookies = Cookies.new(self)
      @network = Network.new(self)
      @tracing = Tracing.new(self)

      subscribe
      prepare_page
    end

    def context
      @browser.contexts.find_by(target_id: target_id)
    end

    #
    # Navigates the page to a URL.
    #
    # @param [String, nil] url
    #   The URL to navigate to. The url should include scheme unless you set
    #   `{Browser#base_url = url}` when configuring driver.
    #
    # @example
    #   browser.go_to("https://github.com/")
    #
    def go_to(url = nil)
      options = { url: combine_url!(url) }
      options.merge!(referrer: referrer) if referrer
      response = command("Page.navigate", wait: GOTO_WAIT, **options)
      error_text = response["errorText"]
      raise StatusError.new(options[:url], "Request to #{options[:url]} failed (#{error_text})") if error_text

      response["frameId"]
    rescue TimeoutError
      if @browser.options.pending_connection_errors
        pendings = network.traffic.select(&:pending?).map(&:url).compact
        raise PendingConnectionsError.new(options[:url], pendings) unless pendings.empty?
      end
    end
    alias goto go_to
    alias go go_to

    def close
      @headers.clear
      @browser.command("Target.closeTarget", targetId: @target_id)
      @client.close
    end

    def resize(width: nil, height: nil, fullscreen: false)
      if fullscreen
        width, height = document_size
        set_window_bounds(windowState: "fullscreen")
      else
        set_window_bounds(windowState: "normal")
        set_window_bounds(width: width, height: height)
      end

      command("Emulation.setDeviceMetricsOverride", slowmoable: true,
                                                    width: width,
                                                    height: height,
                                                    deviceScaleFactor: 0,
                                                    mobile: false)
    end

    #
    # The current position of the browser window.
    #
    # @return [(Integer, Integer)]
    #   The left, top coordinates of the browser window.
    #
    # @example
    #   browser.position # => [10, 20]
    #
    def position
      @browser.command("Browser.getWindowBounds", windowId: window_id).fetch("bounds").values_at("left", "top")
    end

    #
    # Sets the position of the browser window.
    #
    # @param [Hash{Symbol => Object}] options
    #
    # @option options [Integer] :left
    #   The number of pixels from the left-hand side of the screen.
    #
    # @option options [Integer] :top
    #   The number of pixels from the top of the screen.
    #
    # @example
    #   browser.position = { left: 10, top: 20 }
    #
    def position=(options)
      @browser.command("Browser.setWindowBounds",
                       windowId: window_id,
                       bounds: { left: options[:left], top: options[:top] })
    end

    #
    # Reloads the current page.
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.refresh
    #
    def refresh
      command("Page.reload", wait: timeout, slowmoable: true)
    end
    alias reload refresh

    #
    # Stop all navigations and loading pending resources on the page.
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.stop
    #
    def stop
      command("Page.stopLoading", slowmoable: true)
    end

    #
    # Navigates to the previous URL in the browser's history.
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.at_xpath("//a").click
    #   browser.back
    #
    def back
      history_navigate(delta: -1)
    end

    #
    # Navigates to the next URL in the browser's history.
    #
    # @example
    #   browser.go_to("https://github.com/")
    #   browser.at_xpath("//a").click
    #   browser.back
    #   browser.forward
    #
    def forward
      history_navigate(delta: 1)
    end

    def wait_for_reload(sec = 1)
      @event.reset if @event.set?
      @event.wait(sec)
      @event.set
    end

    #
    # Enables/disables CSP bypass.
    #
    # @param [Boolean] enabled
    #
    # @return [Boolean]
    #
    # @example
    #   browser.bypass_csp # => true
    #   browser.go_to("https://github.com/ruby-concurrency/concurrent-ruby/blob/master/docs-source/promises.in.md")
    #   browser.refresh
    #   browser.add_script_tag(content: "window.__injected = 42")
    #   browser.evaluate("window.__injected") # => 42
    #
    def bypass_csp(enabled: true)
      command("Page.setBypassCSP", enabled: enabled)
      enabled
    end

    def window_id
      @browser.command("Browser.getWindowForTarget", targetId: @target_id)["windowId"]
    end

    def set_window_bounds(bounds = {})
      @browser.command("Browser.setWindowBounds", windowId: window_id, bounds: bounds)
    end

    def command(method, wait: 0, slowmoable: false, **params)
      iteration = @event.reset if wait.positive?
      sleep(@browser.options.slowmo) if slowmoable && @browser.options.slowmo.positive?
      result = @client.command(method, params)

      if wait.positive?
        # Wait a bit after command and check if iteration has
        # changed which means there was some network event for
        # the main frame and it started to load new content.
        @event.wait(wait)
        if iteration != @event.iteration
          set = @event.wait(timeout)
          raise TimeoutError unless set
        end
      end
      result
    end

    def on(name, &block)
      case name
      when :dialog
        @client.on("Page.javascriptDialogOpening") do |params, index, total|
          dialog = Dialog.new(self, params)
          block.call(dialog, index, total)
        end
      when :request
        @client.on("Fetch.requestPaused") do |params, index, total|
          request = Network::InterceptedRequest.new(self, params)
          exchange = network.select(request.network_id).last
          exchange ||= network.build_exchange(request.network_id)
          exchange.intercepted_request = request
          block.call(request, index, total)
        end
      when :auth
        @client.on("Fetch.authRequired") do |params, index, total|
          request = Network::AuthRequest.new(self, params)
          block.call(request, index, total)
        end
      else
        @client.on(name, &block)
      end
    end

    def subscribed?(event)
      @client.subscribed?(event)
    end

    def use_proxy?
      @proxy_host && @proxy_port
    end

    def use_authorized_proxy?
      use_proxy? && @proxy_user && @proxy_password
    end

    def document_node_id
      command("DOM.getDocument", depth: 0).dig("root", "nodeId")
    end

    private

    def subscribe
      frames_subscribe
      network.subscribe

      if @browser.options.logger
        on("Runtime.consoleAPICalled") do |params|
          params["args"].each { |r| @browser.options.logger.puts(r["value"]) }
        end
      end

      if @browser.options.js_errors
        on("Runtime.exceptionThrown") do |params|
          # FIXME: https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/
          Thread.main.raise JavaScriptError.new(
            params.dig("exceptionDetails", "exception"),
            params.dig("exceptionDetails", "stackTrace")
          )
        end
      end

      on(:dialog) do |dialog, _index, total|
        if total == 1
          warn "Dialog was shown but you didn't provide `on(:dialog)` callback, accepting it by default. " \
               "Please take a look at https://github.com/rubycdp/ferrum#dialogs"
          dialog.accept
        end
      end
    end

    def prepare_page
      command("Page.enable")
      command("Runtime.enable")
      command("DOM.enable")
      command("CSS.enable")
      command("Log.enable")
      command("Network.enable")

      if use_authorized_proxy?
        network.authorize(user: @proxy_user,
                          password: @proxy_password,
                          type: :proxy) do |request, _index, _total|
          request.continue
        end
      end

      if @browser.options.save_path
        unless Pathname.new(@browser.options.save_path).absolute?
          raise Error, "supply absolute path for `:save_path` option"
        end

        @browser.command("Browser.setDownloadBehavior",
                         browserContextId: context.id,
                         downloadPath: @browser.options.save_path,
                         behavior: "allow", eventsEnabled: true)
      end

      @browser.extensions.each do |extension|
        command("Page.addScriptToEvaluateOnNewDocument", source: extension)
      end

      inject_extensions

      width, height = @browser.window_size
      resize(width: width, height: height)

      response = command("Page.getNavigationHistory")
      transition_type = response.dig("entries", 0, "transitionType")
      return if transition_type == "auto_toplevel"

      # If we create page by clicking links, submitting forms and so on it
      # opens a new window for which `frameStoppedLoading` event never
      # occurs and thus search for nodes cannot be completed. Here we check
      # the history and if the transitionType for example `link` then
      # content is already loaded and we can try to get the document.
      document_node_id
    end

    def inject_extensions
      @browser.extensions.each do |extension|
        # https://github.com/GoogleChrome/puppeteer/issues/1443
        # https://github.com/ChromeDevTools/devtools-protocol/issues/77
        # https://github.com/cyrus-and/chrome-remote-interface/issues/319
        # We also evaluate script just in case because
        # `Page.addScriptToEvaluateOnNewDocument` doesn't work in popups.
        command("Runtime.evaluate", expression: extension,
                                    executionContextId: execution_id!,
                                    returnByValue: true)
      end
    end

    def history_navigate(delta:)
      history = command("Page.getNavigationHistory")
      index, entries = history.values_at("currentIndex", "entries")
      entry = entries[index + delta]

      return unless entry

      # Potential wait because of network event
      command("Page.navigateToHistoryEntry",
              wait: Mouse::CLICK_WAIT,
              slowmoable: true,
              entryId: entry["id"])
    end

    def combine_url!(url_or_path)
      url = Addressable::URI.parse(url_or_path)
      nil_or_relative = url.nil? || url.relative?

      if nil_or_relative && !@browser.base_url
        raise "Set :base_url browser's option or use absolute url in `go_to`, you passed: #{url_or_path}"
      end

      (nil_or_relative ? @browser.base_url.join(url.to_s) : url).to_s
    end

    def ws_url
      "ws://#{@browser.process.host}:#{@browser.process.port}/devtools/page/#{@target_id}"
    end

    def proxy=(options)
      @proxy_host = options&.[](:host) || @browser.options.proxy&.[](:host)
      @proxy_port = options&.[](:port) || @browser.options.proxy&.[](:port)
      @proxy_user = options&.[](:user) || @browser.options.proxy&.[](:user)
      @proxy_password = options&.[](:password) || @browser.options.proxy&.[](:password)
    end
  end
end
