# frozen_string_literal: true

module Ferrum
  class Browser
    class Command
      NOT_FOUND = "Could not find an executable for the browser. Try to make " \
                  "it available on the PATH or set environment variable for " \
                  "example BROWSER_PATH=\"/usr/bin/chrome\""

      # Currently only these browsers support CDP:
      # https://github.com/cyrus-and/chrome-remote-interface#implementations
      def self.build(options, user_data_dir)
        defaults = case options.browser_name
                   when :firefox
                     Options::Firefox.options
                   when :chrome, :opera, :edge, nil
                     Options::Chrome.options
                   else
                     raise NotImplementedError, "not supported browser"
                   end

        new(defaults, options, user_data_dir)
      end

      attr_reader :defaults, :path, :options

      def initialize(defaults, options, user_data_dir)
        @flags = {}
        @defaults = defaults
        @options = options
        @user_data_dir = user_data_dir
        @path = options.browser_path || ENV.fetch("BROWSER_PATH", nil) || defaults.detect_path
        raise BinaryNotFoundError, NOT_FOUND unless @path

        merge_options
      end

      def xvfb?
        !!options.xvfb
      end

      def headless_new?
        @flags["headless"] == "new"
      end

      def to_a
        [path] + @flags.map { |k, v| v.nil? ? "--#{k}" : "--#{k}=#{v}" }
      end

      private

      def merge_options
        @flags = defaults.merge_required(@flags, options, @user_data_dir)
        @flags = defaults.merge_default(@flags, options) unless options.ignore_default_browser_options
        @flags.merge!(options.browser_options)
      end
    end
  end
end
