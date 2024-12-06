# frozen_string_literal: true

require "base64"
require "forwardable"
require "ferrum/page"
require "ferrum/proxy"
require "ferrum/contexts"
require "ferrum/browser/xvfb"
require "ferrum/browser/options"
require "ferrum/browser/process"
require "ferrum/browser/client"
require "ferrum/browser/binary"
require "ferrum/browser/version_info"

module Ferrum
  class Browser
    extend Forwardable
    delegate %i[default_context] => :contexts
    delegate %i[targets create_target page pages windows] => :default_context
    delegate %i[go_to goto go back forward refresh reload stop wait_for_reload
                at_css at_xpath css xpath current_url current_title url title
                body doctype content=
                headers cookies network
                mouse keyboard
                screenshot pdf mhtml viewport_size device_pixel_ratio
                frames frame_by main_frame
                evaluate evaluate_on evaluate_async execute evaluate_func
                add_script_tag add_style_tag bypass_csp
                on position position=
                playback_rate playback_rate=] => :page
    delegate %i[default_user_agent] => :process

    attr_reader :client, :process, :contexts, :options, :window_size, :base_url
    attr_accessor :timeout

    #
    # Initializes the browser.
    #
    # @param [Hash{Symbol => Object}, nil] options
    #   Additional browser options.
    #
    # @option options [Boolean] :headless (true)
    #   Set browser as headless or not.
    #
    # @option options [Boolean] :xvfb (false)
    #   Run browser in a virtual framebuffer.
    #
    # @option options [(Integer, Integer)] :window_size ([1024, 768])
    #   The dimensions of the browser window in which to test, expressed as a
    #   2-element array, e.g. `[1024, 768]`.
    #
    # @option options [Array<String, Hash>] :extensions
    #   An array of paths to files or JS source code to be preloaded into the
    #   browser e.g.: `["/path/to/script.js", { source: "window.secret = 'top'" }]`
    #
    # @option options [#puts] :logger
    #   When present, debug output is written to this object.
    #
    # @option options [Integer, Float] :slowmo
    #   Set a delay in seconds to wait before sending command.
    #   Useful companion of headless option, so that you have time to see
    #   changes.
    #
    # @option options [Numeric] :timeout (5)
    #   The number of seconds we'll wait for a response when communicating with
    #   browser.
    #
    # @option options [Boolean] :js_errors
    #   When true, JavaScript errors get re-raised in Ruby.
    #
    # @option options [Boolean] :pending_connection_errors (true)
    #   When main frame is still waiting for slow responses while timeout is
    #   reached {PendingConnectionsError} is raised. It's better to figure out
    #   why you have slow responses and fix or block them rather than turn this
    #   setting off.
    #
    # @option options [:chrome, :firefox] :browser_name (:chrome)
    #   Sets the browser's name. **Note:** only experimental support for
    #   `:firefox` for now.
    #
    # @option options [String] :browser_path
    #   Path to Chrome binary, you can also set ENV variable as
    #   `BROWSER_PATH=some/path/chrome bundle exec rspec`.
    #
    # @option options [Hash] :browser_options
    #   Additional command line options, [see them all](https://peter.sh/experiments/chromium-command-line-switches/)
    #   e.g. `{ "ignore-certificate-errors" => nil }`
    #
    # @option options [Boolean] :ignore_default_browser_options
    #   Ferrum has a number of default options it passes to the browser,
    #   if you set this to `true` then only options you put in
    #   `:browser_options` will be passed to the browser, except required ones
    #   of course.
    #
    # @option options [Integer] :port
    #   Remote debugging port for headless Chrome.
    #
    # @option options [String] :host
    #   Remote debugging address for headless Chrome.
    #
    # @option options [String] :url
    #   URL for a running instance of Chrome. If this is set, a browser process
    #   will not be spawned.
    #
    # @option options [Integer] :process_timeout
    #   How long to wait for the Chrome process to respond on startup.
    #
    # @option options [Integer] :ws_max_receive_size
    #   How big messages to accept from Chrome over the web socket, in bytes.
    #   Defaults to 64MB. Incoming messages larger this will cause a
    #   {Ferrum::DeadBrowserError}.
    #
    # @option options [Hash] :proxy
    #   Specify proxy settings, [read more](https://github.com/rubycdp/ferrum#proxy).
    #
    # @option options [String] :save_path
    #   Path to save attachments with [Content-Disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition)
    #   header.
    #
    # @option options [Hash] :env
    #   Environment variables you'd like to pass through to the process.
    #
    def initialize(options = nil)
      @options = Options.new(options)
      @client = @process = @contexts = nil

      @timeout = @options.timeout
      @window_size = @options.window_size
      @base_url = @options.base_url if @options.base_url

      start
    end

    #
    # Sets the base URL.
    #
    # @param [String] value
    #   The new base URL value.
    #
    # @raise [ArgumentError] when path is not absolute or doesn't include schema
    #
    # @return [Addressable::URI]
    #   The parsed base URI value.
    #
    def base_url=(value)
      @base_url = options.parse_base_url(value)
    end

    #
    # Creates a new page.
    #
    # @param [Boolean] new_context
    #   Whether to create a page in a new context or not.
    #
    # @param [Hash] proxy
    #   Whether to use proxy for a page. The page will be created in a new context if so.
    #
    # @return [Ferrum::Page]
    #   Created page.
    #
    def create_page(new_context: false, proxy: nil)
      page = if new_context || proxy
               params = {}

               if proxy
                 options.parse_proxy(proxy)
                 params.merge!(proxyServer: "#{proxy[:host]}:#{proxy[:port]}")
                 params.merge!(proxyBypassList: proxy[:bypass]) if proxy[:bypass]
               end

               context = contexts.create(**params)
               context.create_page(proxy: proxy)
             else
               default_context.create_page
             end

      block_given? ? yield(page) : page
    ensure
      if block_given?
        page&.close
        context.dispose if new_context
      end
    end

    def extensions
      @extensions ||= Array(options.extensions).map do |ext|
        (ext.is_a?(Hash) && ext[:source]) || File.read(ext)
      end
    end

    #
    # Evaluate JavaScript to modify things before a page load.
    #
    # @param [String] expression
    #   The JavaScript to add to each new document.
    #
    # @example
    #   browser.evaluate_on_new_document <<~JS
    #     Object.defineProperty(navigator, "languages", {
    #       get: function() { return ["tlh"]; }
    #     });
    #   JS
    #
    def evaluate_on_new_document(expression)
      extensions << expression
    end

    def command(*args)
      @client.command(*args)
    rescue DeadBrowserError
      restart
      raise
    end

    #
    # Closes browser tabs opened by the `Browser` instance.
    #
    # @example
    #   # connect to a long-running Chrome process
    #   browser = Ferrum::Browser.new(url: 'http://localhost:9222')
    #
    #   browser.go_to("https://github.com/")
    #
    #   # clean up, lest the tab stays there hanging forever
    #   browser.reset
    #
    #   browser.quit
    #
    def reset
      @window_size = options.window_size
      contexts.reset
    end

    def restart
      quit
      start
    end

    def quit
      return unless @client

      @client.close
      @process.stop
      @client = @process = @contexts = nil
    end

    def resize(**options)
      @window_size = [options[:width], options[:height]]
      page.resize(**options)
    end

    def crash
      command("Browser.crash")
    end

    #
    # Gets the version information from the browser.
    #
    # @return [VersionInfo]
    #
    # @since 0.13
    #
    def version
      VersionInfo.new(command("Browser.getVersion"))
    end

    def headless_new?
      process&.command&.headless_new?
    end

    private

    def start
      Utils::ElapsedTime.start
      @process = Process.start(options)
      @client = Client.new(@process.ws_url, self,
                           logger: options.logger,
                           ws_max_receive_size: options.ws_max_receive_size)
      @contexts = Contexts.new(self)
    end
  end
end
