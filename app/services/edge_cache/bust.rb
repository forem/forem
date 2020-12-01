module EdgeCache
  class Bust
    def self.call(path)
      bust(path)
    end

    class << self
      protected

      def bust(path)
        provider_class = determine_provider_class

        return unless provider_class

        if provider_class.respond_to?(:call)
          provider_class.call(path)

          true
        else
          Rails.logger.warn("#{provider_class} cannot be used without a #call implementation!")
          DatadogStatsClient.increment("edgecache_bust.invalid_provider_class",
                                       tags: ["provider_class:#{provider_class}"])
          false
        end
      end
    end

    def self.determine_provider_class
      provider =
        if fastly_enabled?
          "fastly"
        elsif nginx_enabled?
          "nginx"
        end

      return unless provider

      const_get(provider.capitalize)
    end

    private_class_method :determine_provider_class

    def self.fastly_enabled?
      ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
    end

    private_class_method :fastly_enabled?

    def self.nginx_enabled?
      ApplicationConfig["OPENRESTY_URL"].present?
    end

    private_class_method :nginx_enabled?
  end
end
