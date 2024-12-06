# frozen_string_literal: true

require 'digest/sha1'

require 'faraday/http_cache/strategies/base_strategy'

module Faraday
  class HttpCache < Faraday::Middleware
    module Strategies
      # This strategy uses headers from the Vary response header to generate cache keys.
      # It also uses the index with Vary headers mapped to the request url.
      # This strategy is more suitable for caching private responses with the same urls,
      # like https://api.github.com/user.
      #
      # This strategy does not support #delete method to clear cache on unsafe methods.
      class ByVary < BaseStrategy
        # Store a response inside the cache.
        #
        # @param [Faraday::HttpCache::Request] request - instance of the executed HTTP request.
        # @param [Faraday::HttpCache::Response] response - instance to be stored.
        #
        # @return [void]
        def write(request, response)
          vary_cache_key = vary_cache_key_for(request)
          headers = Faraday::Utils::Headers.new(response.payload[:response_headers])
          vary = headers['Vary'].to_s
          cache.write(vary_cache_key, vary)

          response_cache_key = response_cache_key_for(request, vary)
          entry = serialize_object(response.serializable_hash)
          cache.write(response_cache_key, entry)
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
          vary_cache_key = vary_cache_key_for(request)
          vary = cache.read(vary_cache_key)
          return nil if vary.nil? || vary == '*'

          cache_key = response_cache_key_for(request, vary)
          response = cache.read(cache_key)
          return nil if response.nil?

          Faraday::HttpCache::Response.new(deserialize_object(response))
        end

        # This strategy does not support #delete method to clear cache on unsafe methods.
        # @return [void]
        def delete(_url)
          # do nothing since we can't find the key by url
        end

        private

        # Computes the cache key for the index with Vary headers.
        #
        # @param [Faraday::HttpCache::Request] request - instance of the executed HTTP request.
        #
        # @return [String]
        def vary_cache_key_for(request)
          method = request.method.to_s
          Digest::SHA1.hexdigest("by_vary_index#{@cache_salt}#{method}#{request.url}")
        end

        # Computes the cache key for the response.
        #
        # @param [Faraday::HttpCache::Request] request - instance of the executed HTTP request.
        # @param [String] vary - the Vary header value.
        #
        # @return [String]
        def response_cache_key_for(request, vary)
          method = request.method.to_s
          headers = vary.split(/[\s,]+/).uniq.sort.map { |header| request.headers[header] }
          Digest::SHA1.hexdigest("by_vary#{@cache_salt}#{method}#{request.url}#{headers.join}")
        end
      end
    end
  end
end
