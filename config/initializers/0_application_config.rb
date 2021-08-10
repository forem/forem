class ApplicationConfig
  URI_REGEXP = %r{(?<scheme>https?://)?(?<host>.+?)(?<port>:\d+)?$}.freeze

  def self.[](key)
    if ENV.key?(key)
      ENV[key]
    else
      Rails.logger.debug { "Unset ENV variable: #{key}." }
      nil
    end
  end

  def self.app_domain_no_port
    app_domain = self["APP_DOMAIN"]
    return unless app_domain

    app_domain.match(URI_REGEXP)[:host]
  end
end
