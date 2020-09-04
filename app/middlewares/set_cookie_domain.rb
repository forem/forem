class SetCookieDomain
  def initialize(app, default_domain)
    @app = app
    @default_domain = default_domain
  end

  def call(env)
    env["rack.session.options"][:domain] = ".#{ENV['HTTP_HOST'] || ENV['HTTP_X_FORWARDED_HOST']}"
    @app.call(env)
  end

  # def custom_domain
  #   domain = @default_domain.sub(/^\./, "")
  #   host !~ Regexp.new("#{domain}$", Regexp::IGNORECASE)
  # end
end
