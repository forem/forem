# frozen_string_literal: true

module Ferrum
  class Browser
    class Options
      HEADLESS = true
      BROWSER_PORT = "0"
      BROWSER_HOST = "127.0.0.1"
      WINDOW_SIZE = [1024, 768].freeze
      BASE_URL_SCHEMA = %w[http https].freeze
      DEFAULT_TIMEOUT = ENV.fetch("FERRUM_DEFAULT_TIMEOUT", 5).to_i
      PROCESS_TIMEOUT = ENV.fetch("FERRUM_PROCESS_TIMEOUT", 10).to_i
      DEBUG_MODE = !ENV.fetch("FERRUM_DEBUG", nil).nil?

      attr_reader :window_size, :timeout, :logger, :ws_max_receive_size,
                  :js_errors, :base_url, :slowmo, :pending_connection_errors,
                  :url, :env, :process_timeout, :browser_name, :browser_path,
                  :save_path, :extensions, :proxy, :port, :host, :headless,
                  :ignore_default_browser_options, :browser_options, :xvfb

      def initialize(options = nil)
        @options = Hash(options&.dup)
        @port = @options.fetch(:port, BROWSER_PORT)
        @host = @options.fetch(:host, BROWSER_HOST)
        @timeout = @options.fetch(:timeout, DEFAULT_TIMEOUT)
        @window_size = @options.fetch(:window_size, WINDOW_SIZE)
        @js_errors = @options.fetch(:js_errors, false)
        @headless = @options.fetch(:headless, HEADLESS)
        @pending_connection_errors = @options.fetch(:pending_connection_errors, true)
        @process_timeout = @options.fetch(:process_timeout, PROCESS_TIMEOUT)
        @browser_options = @options.fetch(:browser_options, {})
        @slowmo = @options[:slowmo].to_f

        @ws_max_receive_size, @env, @browser_name, @browser_path,
          @save_path, @extensions, @ignore_default_browser_options, @xvfb = @options.values_at(
            :ws_max_receive_size, :env, :browser_name, :browser_path, :save_path, :extensions,
            :ignore_default_browser_options, :xvfb
          )

        @options[:window_size] = @window_size
        @proxy = parse_proxy(@options[:proxy])
        @logger = parse_logger(@options[:logger])
        @base_url = parse_base_url(@options[:base_url]) if @options[:base_url]
        @url = @options[:url].to_s if @options[:url]

        @options.freeze
        @browser_options.freeze
      end

      def to_h
        @options
      end

      def parse_base_url(value)
        parsed = Addressable::URI.parse(value)
        unless BASE_URL_SCHEMA.include?(parsed&.normalized_scheme)
          raise ArgumentError, "`base_url` should be absolute and include schema: #{BASE_URL_SCHEMA.join(' | ')}"
        end

        parsed
      end

      def parse_proxy(options)
        return unless options

        raise ArgumentError, "proxy options must be a Hash" unless options.is_a?(Hash)

        if options[:host].nil? && options[:port].nil?
          raise ArgumentError, "proxy options must be a Hash with at least :host | :port"
        end

        options
      end

      private

      def parse_logger(logger)
        return logger if logger

        !logger && DEBUG_MODE ? $stdout.tap { |s| s.sync = true } : logger
      end
    end
  end
end
