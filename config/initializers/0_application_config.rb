ENVied.require(*ENV["ENVIED_GROUPS"] || Rails.groups)

class ApplicationConfig
  def self.[](key)
    ENVied.send(key)
  end

  def self.app_domain_no_port
    app_domain = self["APP_DOMAIN"]
    match = app_domain.match(/^(?<host>.+?)(?<port>:\d+)?$/)
    match[:host]
  end
end
