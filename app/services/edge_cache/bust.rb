module EdgeCache
  class Bust
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
      @response = nil
    end

    def call
      return unless provider

      provider_class = "#{self.class}::#{provider.capitalize}".constantize

      if provider_class.respond_to?(:call)
        @response = provider_class.call(path)
      else
        @response = nil
        Rails.logger.warn("#{provider_class} cannot be used without a #call implementation!")
        DatadogStatsClient.increment("edgecache_bust.invalid_provider_class",
                                     tags: ["provider_class:#{provider_class}"])
      end

      self
    end

    attr_reader :provider, :path, :response

    private

    def determine_provider
      if fastly_enabled?
        "fastly"
      elsif nginx_enabled?
        "nginx"
      end
    end

    def fastly_enabled?
      ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
    end

    def nginx_enabled?
      ApplicationConfig["OPENRESTY_PROTOCOL"].present? && ApplicationConfig["OPENRESTY_DOMAIN"].present?
    end
  end
end
