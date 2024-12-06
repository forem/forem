# frozen_string_literal: true

module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A class to represent a request
    class Request
      class << self
        def from_env(env)
          hash = env.to_hash
          new(method: hash[:method], url: hash[:url], headers: hash[:request_headers].dup)
        end
      end

      attr_reader :method, :url, :headers

      def initialize(method:, url:, headers:)
        @method = method
        @url = url
        @headers = headers
      end

      # Internal: Validates if the current request method is valid for caching.
      #
      # Returns true if the method is ':get' or ':head'.
      def cacheable?
        return false if method != :get && method != :head
        return false if cache_control.no_store?

        true
      end

      def no_cache?
        cache_control.no_cache?
      end

      # Internal: Gets the 'CacheControl' object.
      def cache_control
        @cache_control ||= CacheControl.new(headers['Cache-Control'])
      end

      def serializable_hash
        {
          method: @method,
          url: @url.to_s,
          headers: @headers
        }
      end
    end
  end
end
