module EdgeCache
  class Buster
    class Nginx
      def self.call(path)
        uri = URI.parse("#{ApplicationConfig['OPENRESTY_URL']}#{path}")
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.request Net::HTTP::Purge.new(uri.request_uri)

        raise StandardError, "Nginx Purge request failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        response.body
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
