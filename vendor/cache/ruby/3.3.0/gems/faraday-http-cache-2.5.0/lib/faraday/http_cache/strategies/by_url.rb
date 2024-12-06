# frozen_string_literal: true

require 'digest/sha1'

require 'faraday/http_cache/strategies/base_strategy'

module Faraday
  class HttpCache < Faraday::Middleware
    module Strategies
      # The original strategy by Faraday::HttpCache.
      # Uses URL + HTTP method to generate cache keys.
      class ByUrl < BaseStrategy
        # Store a response inside the cache.
        #
        # @param [Faraday::HttpCache::Request] request - instance of the executed HTTP request.
        # @param [Faraday::HttpCache::Response] response - instance to be stored.
        #
        # @return [void]
        def write(request, response)
          key = cache_key_for(request.url)
          entry = serialize_entry(request.serializable_hash, response.serializable_hash)
          entries = cache.read(key) || []
          entries = entries.dup if entries.frozen?
          entries.reject! do |(cached_request, cached_response)|
            response_matches?(request, deserialize_object(cached_request), deserialize_object(cached_response))
          end

          entries << entry

          cache.write(key, entries)
        rescue ::Encoding::UndefinedConversionError => e
          warn "Response could not be serialized: #{e.message}. Try using Marshal to serialize."
          raise e
        end

        # Fetch a stored response that suits the incoming HTTP request or return nil.
        #
        # @param [Faraday::HttpCache::Request] request - an instance of the incoming HTTP request.
        #
        # @return [Faraday::HttpCache::Response, nil]
        def read(request)
          cache_key = cache_key_for(request.url)
          entries = cache.read(cache_key)
          response = lookup_response(request, entries)
          return nil unless response

          Faraday::HttpCache::Response.new(response)
        end

        # @param [String] url – the url of a changed resource, will be used to invalidate the cache.
        #
        # @return [void]
        def delete(url)
          cache_key = cache_key_for(url)
          cache.delete(cache_key)
        end

        private

        # Retrieve a response Hash from the list of entries that match the given request.
        #
        # @param [Faraday::HttpCache::Request] request - an instance of the incoming HTTP request.
        # @param [Array<Array(Hash, Hash)>] entries - pairs of Hashes (request, response).
        #
        # @return [Hash, nil]
        def lookup_response(request, entries)
          if entries
            entries = entries.map { |entry| deserialize_entry(*entry) }
            _, response = entries.find { |req, res| response_matches?(request, req, res) }
            response
          end
        end

        # Check if a cached response and request matches the given request.
        #
        # @param [Faraday::HttpCache::Request] request - an instance of the incoming HTTP request.
        # @param [Hash] cached_request - a Hash of the request that was cached.
        # @param [Hash] cached_response - a Hash of the response that was cached.
        #
        # @return [true, false]
        def response_matches?(request, cached_request, cached_response)
          request.method.to_s == cached_request[:method].to_s &&
            vary_matches?(cached_response, request, cached_request)
        end

        # Check if the cached request matches the incoming
        # request based on the Vary header of cached response.
        #
        # If Vary header is not present, the request is considered to match.
        # If Vary header is '*', the request is considered to not match.
        #
        # @param [Faraday::HttpCache::Request] request - an instance of the incoming HTTP request.
        # @param [Hash] cached_request - a Hash of the request that was cached.
        # @param [Hash] cached_response - a Hash of the response that was cached.
        #
        # @return [true, false]
        def vary_matches?(cached_response, request, cached_request)
          headers = Faraday::Utils::Headers.new(cached_response[:response_headers])
          vary = headers['Vary'].to_s

          vary.empty? || (vary != '*' && vary.split(/[\s,]+/).all? do |header|
            request.headers[header] == cached_request[:headers][header]
          end)
        end

        # Computes the cache key for a specific request, taking
        # in account the current serializer to avoid cross serialization issues.
        #
        # @param [String] url - the request URL.
        #
        # @return [String]
        def cache_key_for(url)
          Digest::SHA1.hexdigest("#{@cache_salt}#{url}")
        end
      end
    end
  end
end
