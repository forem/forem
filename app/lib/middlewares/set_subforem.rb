# config/initializers/middlewares/set_subforem.rb
module Middlewares
  class SetSubforem
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      domain = request.params["passed_domain"].presence || request.host
      RequestStore.store[:default_subforem_id]     = Subforem.cached_default_id
      RequestStore.store[:subforem_id]             = Subforem.cached_id_by_domain(domain)
      RequestStore.store[:root_subforem_id]        = Subforem.cached_root_id
      RequestStore.store[:root_subforem_domain]    = Subforem.cached_root_domain
      RequestStore.store[:default_subforem_domain] = Subforem.cached_default_domain

      # Call Rails (or next middleware) to get the response
      status, headers, body = @app.call(env)

      # POST-PROCESS HEADERS HERE
      begin
        # Example logic: if a subforem is found, we do custom cookie manipulation
        if RequestStore.store[:subforem_id].present?
          parsed = PublicSuffix.parse(request.host, default_rule: nil)
          subdomain_regexp = /^([^.]+)\.#{parsed.sld}\.#{parsed.tld}$/

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
        end

        # Set Content-Security-Policy header to allow embedding in iframes for all subforems
        headers.delete("X-Frame-Options")
        allowed_domains = Subforem.cached_all_domains + [Settings::General.app_domain]
        csp_value = "frame-ancestors " + allowed_domains.map { |d| "https://#{d}" }.join(" ")
        headers["Content-Security-Policy"] = csp_value

      rescue PublicSuffix::DomainInvalid
        Rails.logger.error("Invalid domain: #{request.host}")
      end

      [status, headers, body]
    end
  end
end
