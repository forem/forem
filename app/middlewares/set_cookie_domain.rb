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
