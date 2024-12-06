# frozen_string_literal: true

module Ferrum
  class Browser
    #
    # The browser's version information returned by [Browser.getVersion].
    #
    # [Browser.getVersion]: https://chromedevtools.github.io/devtools-protocol/1-3/Browser/#method-getVersion
    #
    # @since 0.13
    #
    class VersionInfo
      #
      # Initializes the browser's version information.
      #
      # @param [Hash{String => Object}] properties
      #   The object properties returned by [Browser.getVersion](https://chromedevtools.github.io/devtools-protocol/1-3/Browser/#method-getVersion).
      #
      # @api private
      #
      def initialize(properties)
        @properties = properties
      end

      #
      # The Chrome DevTools protocol version.
      #
      # @return [String]
      #
      def protocol_version
        @properties["protocolVersion"]
      end

      #
      # The Chrome version.
      #
      # @return [String]
      #
      def product
        @properties["product"]
      end

      #
      # The Chrome revision properties.
      #
      # @return [String]
      #
      def revision
        @properties["revision"]
      end

      #
      # The Chrome `User-Agent` string.
      #
      # @return [String]
      #
      def user_agent
        @properties["userAgent"]
      end

      #
      # The JavaScript engine version.
      #
      # @return [String]
      #
      def js_version
        @properties["jsVersion"]
      end
    end
  end
end
