module EdgeCache
  class Bust
    class Nginx
      def self.call(path)
        return unless nginx_available?

        uri = URI.parse("#{ApplicationConfig['OPENRESTY_URL']}#{path}")
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.request Net::HTTP::Purge.new(uri.request_uri)

        raise StandardError, "Nginx Purge request failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end

      def self.nginx_available?
        # TODO: Right now, we are checking that nginx is
        # available on every purge request/call to this bust service. If we are going
        # to bust multiple paths, we should be able to check that nginx is
        # available just once, and persist it on the class with @provider_available?.
        # Then, we could allow for an array of @paths = [] to be passed in,
        # and on single bust instance could bust multiple paths in order.
        uri = URI.parse(ApplicationConfig["OPENRESTY_URL"])
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.get(uri.request_uri)

        return true if response.is_a?(Net::HTTPSuccess)
      rescue StandardError
        # If we can't connect to OpenResty, alert ourselves that
        # it is unavailable and return false.
        Rails.logger.error("Could not connect to OpenResty via #{ApplicationConfig['OPENRESTY_URL']}!")
        ForemStatsClient.increment("edgecache_bust.service_unavailable",
                                   tags: ["path:#{ApplicationConfig['OPENRESTY_URL']}"])
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
