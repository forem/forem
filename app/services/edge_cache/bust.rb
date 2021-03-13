module EdgeCache
  class Bust
    def initialize
      @provider_class = determine_provider_class
    end

    def self.call(*paths)
      new.call(*paths)
    end

    def call(paths)
      return unless @provider_class

      paths = Array.wrap(paths)
      paths.each do |path|
        @provider_class.call(path)
      rescue StandardError => e
        Honeybadger.notify(e)
        ForemStatsClient.increment(
          "edgecache_bust.provider_error",
          tags: ["provider_class:#{@provider_class}", "error_class:#{e.class}"],
        )
      end
    end

    private

    def determine_provider_class
      provider =
        if fastly_enabled?
          "fastly"
        elsif nginx_enabled_and_available?
          "nginx"
        end

      return unless provider

      self.class.const_get(provider.capitalize)
    end

    def fastly_enabled?
      ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
    end

    def nginx_enabled_and_available?
      return false if ApplicationConfig["OPENRESTY_URL"].blank?

      uri = URI.parse(ApplicationConfig["OPENRESTY_URL"])
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.request_uri)

      return true if response.is_a?(Net::HTTPSuccess)
    rescue StandardError
      # If we can't connect to OpenResty, alert ourselves that it is
      # unavailable and return false.
      Rails.logger.error("Could not connect to OpenResty via #{ApplicationConfig['OPENRESTY_URL']}!")
      Honeybadger.notify(e)
      ForemStatsClient.increment("edgecache_bust.service_unavailable",
                                 tags: ["path:#{ApplicationConfig['OPENRESTY_URL']}"])
    end

    false
  end
end
