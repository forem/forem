module Middlewares
  # Fast-path health check middleware for kamal-proxy, load balancers, and orchestrators.
  #
  # Responds to GET/HEAD /up before SetSubforem and SetCookieDomain so readiness probes
  # succeed without requiring database tables or Redis state (e.g., during initial `kamal setup`
  # before migrations run) and without touching session storage.
  class HealthCheck
    HEALTH_PATH = "/up".freeze
    ALLOWED_METHODS = %w[GET HEAD].freeze
    HEADERS = {
      "Content-Type" => "text/html; charset=utf-8",
      "Cache-Control" => "no-store"
    }.freeze
    BODY = [%(<!DOCTYPE html><html><body style="background-color: green"></body></html>)].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      method = env[Rack::REQUEST_METHOD]
      if env[Rack::PATH_INFO] == HEALTH_PATH && ALLOWED_METHODS.include?(method)
        return [200, HEADERS.dup, method == "HEAD" ? [] : BODY]
      end

      @app.call(env)
    end
  end
end
