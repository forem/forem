# Since we must explicitly set the cookie domain in session_store before SiteConfig is available,
# this ensures we properly set the cookie to SiteConfig.app_domain at runtime.

class SetCookieDomain
  def initialize(app)
    @app = app
  end

  def call(env)
    if Rails.env.production?
      env["rack.session.options"][:domain] = ".#{SiteConfig.app_domain}"
    end
    @app.call(env)
  end
end
