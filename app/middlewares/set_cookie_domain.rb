class SetCookieDomain
  def initialize(app, default_domain)
    @app = app
    @default_domain = default_domain
  end

  def call(env)
    if Rails.env.production?
      env["rack.session.options"][:domain] = ".#{SiteConfig.app_domain}"
    end
    @app.call(env)
  end

  # def custom_domain
  #   domain = @default_domain.sub(/^\./, "")
  #   host !~ Regexp.new("#{domain}$", Regexp::IGNORECASE)
  # end
end
