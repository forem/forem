class ApplicationConfig
  URI_REGEXP = %r{(?<scheme>https?://)?(?<host>.+?)(?<port>:\d+)?$}.freeze

  def self.[](key)
    ENV[key]
  end

  def self.app_domain_no_port
    app_domain = self["APP_DOMAIN"]
    match = app_domain.match(URI_REGEXP)
    match[:host]
  end
end
