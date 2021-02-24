module EdgeCache
  class Buster
    TIMEFRAMES = [
      [-> { 1.week.ago }, "week"],
      [-> { 1.month.ago }, "month"],
      [-> { 1.year.ago }, "year"],
      [-> { 5.years.ago }, "infinity"],
    ].freeze

    def initialize
      @provider_class = determine_provider_class
    end

    def bust(path)
      return unless @provider_class

      if @provider_class.respond_to?(:call)
        @provider_class.call(path)

        true
      else
        Rails.logger.warn("#{@provider_class} cannot be used without a #call implementation!")
        ForemStatsClient.increment("edgecache_bust.invalid_provider_class",
                                   tags: ["provider_class:#{@provider_class}"])
        false
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
      ForemStatsClient.increment("edgecache_bust.service_unavailable",
                                 tags: ["path:#{ApplicationConfig['OPENRESTY_URL']}"])
      false
    end
  end
end
