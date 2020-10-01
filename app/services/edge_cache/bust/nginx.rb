module EdgeCache
  class Bust
    class Nginx
      def self.call(path)
        return unless nginx_available?

        uri = URI.parse("#{openresty_path}#{path}")
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.request Net::HTTP::Purge.new(uri.request_uri)

        raise StandardError, "Nginx Purge request failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end

      def self.openresty_path
        "#{ApplicationConfig['OPENRESTY_PROTOCOL']}#{ApplicationConfig['OPENRESTY_DOMAIN']}"
      end

      def self.nginx_available?
        uri = URI.parse(openresty_path)
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.get(uri.request_uri)

        return true if response.is_a?(Net::HTTPSuccess)
      rescue StandardError
        # If we can't connect to Openresty, alert ourselves that
        # it is unavailable and return false.
        Rails.logger.error("Could not connect to Openresty via #{openresty_path}!")
        DatadogStatsClient.increment("edgecache_bust.service_unavailable", tags: ["path:#{openresty_path}"])
        false
      end
    end
  end
end

# Creates our own purge method for an HTTP request,
# which is used by Nginx to bust a cache.
# See Net::HTTPGenericRequest for attributes/methods.
class Net::HTTP::Purge < Net::HTTPRequest # rubocop:disable Style/ClassAndModuleChildren
  METHOD = "PURGE".freeze
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end
