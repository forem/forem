require 'honeybadger/util/sanitizer'

module Honeybadger
  module Util
    # Constructs/sanitizes request data for notices
    module RequestPayload
      # Default values to use for request data.
      DEFAULTS = {
        url: nil,
        component: nil,
        action: nil,
        params: {}.freeze,
        session: {}.freeze,
        cgi_data: {}.freeze
      }.freeze

      # Allowed keys.
      KEYS = DEFAULTS.keys.freeze

      # The cgi_data key where the raw Cookie header is stored.
      HTTP_COOKIE_KEY = 'HTTP_COOKIE'.freeze

      def self.build(opts = {})
        sanitizer = opts.fetch(:sanitizer) { Sanitizer.new }

        payload = DEFAULTS.dup
        KEYS.each do |key|
          next unless opts[key]
          payload[key] = sanitizer.sanitize(opts[key])
        end

        payload[:url] = sanitizer.filter_url(payload[:url]) if payload[:url]
        if payload[:cgi_data][HTTP_COOKIE_KEY]
          payload[:cgi_data][HTTP_COOKIE_KEY] = sanitizer.filter_cookies(payload[:cgi_data][HTTP_COOKIE_KEY])
        end

        payload
      end
    end
  end
end
