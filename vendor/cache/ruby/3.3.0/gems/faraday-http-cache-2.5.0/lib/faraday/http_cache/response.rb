# frozen_string_literal: true

require 'time'
require 'faraday/http_cache/cache_control'

module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A class to represent a response from a Faraday request.
    # It decorates the response hash into a smarter object that queries
    # the response headers and status informations about how the caching
    # middleware should handle this specific response.
    class Response
      # Internal: List of status codes that can be cached:
      # * 200 - 'OK'
      # * 203 - 'Non-Authoritative Information'
      # * 300 - 'Multiple Choices'
      # * 301 - 'Moved Permanently'
      # * 302 - 'Found'
      # * 404 - 'Not Found'
      # * 410 - 'Gone'
      CACHEABLE_STATUS_CODES = [200, 203, 300, 301, 302, 307, 404, 410].freeze

      # Internal: Gets the actual response Hash (status, headers and body).
      attr_reader :payload

      # Internal: Gets the 'Last-Modified' header from the headers Hash.
      attr_reader :last_modified

      # Internal: Gets the 'ETag' header from the headers Hash.
      attr_reader :etag

      # Internal: Initialize a new Response with the response payload from
      # a Faraday request.
      #
      # payload - the response Hash returned by a Faraday request.
      #           :status - the status code from the response.
      #           :response_headers - a 'Hash' like object with the headers.
      #           :body - the response body.
      def initialize(payload = {})
        @now = Time.now
        @payload = payload
        wrap_headers!
        ensure_date_header!

        @last_modified = headers['Last-Modified']
        @etag = headers['ETag']
      end

      # Internal: Checks the response freshness based on expiration headers.
      # The calculated 'ttl' should be present and bigger than 0.
      #
      # Returns true if the response is fresh, otherwise false.
      def fresh?
        !cache_control.no_cache? && ttl && ttl > 0
      end

      # Internal: Checks if the Response returned a 'Not Modified' status.
      #
      # Returns true if the response status code is 304.
      def not_modified?
        @payload[:status] == 304
      end

      # Internal: Checks if the response can be cached by the client when the
      # client is acting as a shared cache per RFC 2616. This is validated by
      # the 'Cache-Control' directives, the response status code and it's
      # freshness or validation status.
      #
      # Returns false if the 'Cache-Control' says that we can't store the
      # response, or it can be stored in private caches only, or if isn't fresh
      # or it can't be revalidated with the origin server. Otherwise, returns
      # true.
      def cacheable_in_shared_cache?
        cacheable?(true)
      end

      # Internal: Checks if the response can be cached by the client when the
      # client is acting as a private cache per RFC 2616. This is validated by
      # the 'Cache-Control' directives, the response status code and it's
      # freshness or validation status.
      #
      # Returns false if the 'Cache-Control' says that we can't store the
      # response, or if isn't fresh or it can't be revalidated with the origin
      # server. Otherwise, returns true.
      def cacheable_in_private_cache?
        cacheable?(false)
      end

      # Internal: Gets the response age in seconds.
      #
      # Returns the 'Age' header if present, or subtracts the response 'date'
      # from the current time.
      def age
        (headers['Age'] || (@now - date)).to_i
      end

      # Internal: Calculates the 'Time to live' left on the Response.
      #
      # Returns the remaining seconds for the response, or nil the 'max_age'
      # isn't present.
      def ttl
        max_age - age if max_age
      end

      # Internal: Parses the 'Date' header back into a Time instance.
      #
      # Returns the Time object.
      def date
        Time.httpdate(headers['Date'])
      end

      # Internal: Gets the response max age.
      # The max age is extracted from one of the following:
      # * The shared max age directive from the 'Cache-Control' header;
      # * The max age directive from the 'Cache-Control' header;
      # * The difference between the 'Expires' header and the response
      #   date.
      #
      # Returns the max age value in seconds or nil if all options above fails.
      def max_age
        cache_control.shared_max_age ||
          cache_control.max_age ||
          (expires && (expires - @now))
      end

      # Internal: Creates a new 'Faraday::Response', merging the stored
      # response with the supplied 'env' object.
      #
      # Returns a new instance of a 'Faraday::Response' with the payload.
      def to_response(env)
        env.update(@payload)
        Faraday::Response.new(env)
      end

      # Internal: Exposes a representation of the current
      # payload that we can serialize and cache properly.
      #
      # Returns a 'Hash'.
      def serializable_hash
        prepare_to_cache

        {
          status: @payload[:status],
          body: @payload[:body],
          response_headers: @payload[:response_headers],
          reason_phrase: @payload[:reason_phrase]
        }
      end

      private

      # Internal: Checks if this response can be revalidated.
      #
      # Returns true if the 'headers' contains a 'Last-Modified' or an 'ETag'
      # entry.
      def validateable?
        headers.key?('Last-Modified') || headers.key?('ETag')
      end

      # Internal: The logic behind cacheable_in_private_cache? and
      # cacheable_in_shared_cache? The logic is the same except for the
      # treatment of the private Cache-Control directive.
      def cacheable?(shared_cache)
        return false if (cache_control.private? && shared_cache) || cache_control.no_store?

        cacheable_status_code? && (validateable? || fresh?)
      end

      # Internal: Validates the response status against the
      # `CACHEABLE_STATUS_CODES' constant.
      #
      # Returns true if the constant includes the response status code.
      def cacheable_status_code?
        CACHEABLE_STATUS_CODES.include?(@payload[:status])
      end

      # Internal: Gets the 'Expires' in a Time object.
      #
      # Returns the Time object, or nil if the header isn't present or isn't RFC 2616 compliant.
      def expires
        @expires ||= headers['Expires'] && Time.httpdate(headers['Expires']) rescue nil # rubocop:disable Style/RescueModifier
      end

      # Internal: Gets the 'CacheControl' object.
      def cache_control
        @cache_control ||= CacheControl.new(headers['Cache-Control'])
      end

      # Internal: Converts the headers 'Hash' into 'Faraday::Utils::Headers'.
      # Faraday actually uses a Hash subclass, `Faraday::Utils::Headers` to
      # store the headers hash. When retrieving a serialized response,
      # the headers object is decoded as a 'Hash' instead of the actual
      # 'Faraday::Utils::Headers' object, so we need to ensure that the
      # 'response_headers' is always a 'Headers' instead of a plain 'Hash'.
      #
      # Returns nothing.
      def wrap_headers!
        headers = @payload[:response_headers]

        @payload[:response_headers] = Faraday::Utils::Headers.new
        @payload[:response_headers].update(headers) if headers
      end

      # Internal: Try to parse the Date header, if it fails set it to @now.
      #
      # Returns nothing.
      def ensure_date_header!
        date
      rescue StandardError
        headers['Date'] = @now.httpdate
      end

      # Internal: Gets the headers 'Hash' from the payload.
      def headers
        @payload[:response_headers]
      end

      # Internal: Prepares the response headers to be cached.
      #
      # It removes the 'Age' header if present to allow cached responses
      # to continue aging while cached. It also normalizes the 'max-age'
      # related headers if the 'Age' header is provided to ensure accuracy
      # once the 'Age' header is removed.
      #
      # Returns nothing.
      def prepare_to_cache
        if headers.key? 'Age'
          cache_control.normalize_max_ages(headers['Age'].to_i)
          headers.delete 'Age'
          headers['Cache-Control'] = cache_control.to_s
        end
      end
    end
  end
end
