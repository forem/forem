module EdgeCache
  class Bust
    PROVIDERS = %w[fastly nginx].freeze

    def self.call(*args)
      new(*args).call
    end

    def initialize(path)
      # TODO: (Vaidehi Joshi) - Right now, we are checking that nginx is
      # available on every purge request/call to this bust service. If we are going
      # to bust multiple paths, we should be able to check that nginx is
      # available just once, and persist it on the class with @provider_available?.
      # Then, we could allow for an array of @paths = [] to be passed in,
      # and on single bust instance could bust multiple paths in order.

      @path = path
      @provider = determine_provider
    end

    def call
      return unless PROVIDERS.include?(provider)

      bust_method = "bust_#{provider}_cache"
      if respond_to?(bust_method, true)
        __send__(bust_method)
      else
        # We theoretically should never hit this unless someone adds a provider
        # but doesn't add the implementation for it into the #call method.
        Rails.logger.warn("EdgeCache::Bust was called with an invalid provider: #{provider}")
        DatadogStatsClient.increment("edgecache_bust.invalid_provider", tags: ["provider:#{provider}"])
      end

      self
    end

    attr_reader :provider, :path

    private

    def determine_provider
      if fastly_enabled?
        "fastly"
      elsif nginx_enabled? && nginx_available?
        "nginx"
      end
    end

    def bust_fastly_cache
      # TODO: (Alex Smith) - It would be "nice to have" the ability to use the
      # Fastly gem here instead of custom API calls.

      # @forem/systems Fastly-enabled forems don't need "flexible" domains.
      HTTParty.post(
        "https://api.fastly.com/purge/https://#{URL.domain}#{path}",
        headers: {
          "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"]
        },
      )
      HTTParty.post(
        "https://api.fastly.com/purge/https://#{URL.domain}#{path}?i=i",
        headers: {
          "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"]
        },
      )
    end

    def bust_nginx_cache
      uri = URI.parse("#{openresty_path}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request Net::HTTP::NginxPurge.new(uri.request_uri)

      raise StandardError, "NginxPurge request failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def fastly_enabled?
      ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
    end

    def nginx_enabled?
      ApplicationConfig["OPENRESTY_PROTOCOL"].present? && ApplicationConfig["OPENRESTY_DOMAIN"].present?
    end

    def openresty_path
      "#{ApplicationConfig['OPENRESTY_PROTOCOL']}#{ApplicationConfig['OPENRESTY_DOMAIN']}"
    end

    def nginx_available?
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

# Creates our own purge method for an HTTP request,
# which is used by Nginx to bust a cache.
# See Net::HTTPGenericRequest for attributes/methods.
class Net::HTTP::NginxPurge < Net::HTTPRequest # rubocop:disable Style/ClassAndModuleChildren
  METHOD = "PURGE".freeze
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end
