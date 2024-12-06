# frozen_string_literal: true

require 'faraday/http_cache/strategies/by_url'

module Faraday
  class HttpCache < Faraday::Middleware
    # @deprecated Use Faraday::HttpCache::Strategies::ByUrl instead.
    class Storage < Faraday::HttpCache::Strategies::ByUrl
      def initialize(*)
        Kernel.warn("Deprecated: #{self.class} is deprecated and will be removed in " \
             'the next major release. Use Faraday::HttpCache::Strategies::ByUrl instead.')
        super
      end
    end
  end
end
