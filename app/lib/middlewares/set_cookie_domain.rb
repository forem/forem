module Middlewares
  # Since we must explicitly set the cookie domain in session_store before Settings::General is available,
  # this ensures we properly set the cookie to Settings::General.app_domain at runtime.
  class SetCookieDomain
    def initialize(app)
      @app = app
    end

    def call(env)
      env["rack.session.options"][:domain] = ".#{root_domain(Settings::General.app_domain)}"

      @app.call(env)
    end

    def root_domain(host)
      # The `default_rule: nil` option ensures it raises an error if the domain is invalid
      parsed = PublicSuffix.parse(host, default_rule: nil)
      parsed.domain  # Returns the domain with TLD, e.g. "example.com"
    rescue PublicSuffix::DomainInvalid
      host
    end
  end
end
