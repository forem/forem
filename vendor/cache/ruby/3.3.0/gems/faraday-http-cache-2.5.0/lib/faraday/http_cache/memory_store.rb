# frozen_string_literal: true

module Faraday
  class HttpCache < Faraday::Middleware
    # @private
    # A Hash based store to be used by strategies
    # when a `store` is not provided for the middleware setup.
    class MemoryStore
      def initialize
        @cache = {}
      end

      def read(key)
        @cache[key]
      end

      def delete(key)
        @cache.delete(key)
      end

      def write(key, value)
        @cache[key] = value
      end
    end
  end
end
