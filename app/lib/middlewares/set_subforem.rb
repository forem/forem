module Middlewares
  class SetSubforem
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      # --- Do any "read-only" request-specific logic here --- #
      domain = request.params["passed_domain"].presence || request.host
      RequestStore.store[:default_subforem_id]     = Subforem.cached_default_id
      RequestStore.store[:subforem_id]             = Subforem.cached_id_by_domain(domain)
      RequestStore.store[:root_subforem_id]        = Subforem.cached_root_id
      RequestStore.store[:root_subforem_domain]    = Subforem.cached_root_domain
      RequestStore.store[:default_subforem_domain] = Subforem.cached_default_domain
      # ------------------------------------------------------ #

      # Call the next middleware (or Rails) to get status/headers/body
      status, headers, body = @app.call(env)

      # Now that we have 'headers', we can modify them.
      subdomain_regexp = /^([^.]+)\.example\.com$/
      if request.host =~ subdomain_regexp
        # Remove your session cookie (or any other cookie) from subdomain
        Rack::Utils.delete_cookie_header!(
          headers,
          ApplicationConfig["SESSION_KEY"],
          domain: request.host
        )

        # Also remove 'remember_user_token' or other cookies if needed
        Rack::Utils.delete_cookie_header!(
          headers,
          "remember_user_token",
          domain: request.host
        )
      end

      [status, headers, body]
    end
  end
end
