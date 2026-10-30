# config/initializers/middlewares/set_subforem.rb
module Middlewares
  class SetSubforem
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      raw_domain = valid_passed_domain(request).presence || request.host
      domain = ForemNative.subforem_request_domain(raw_domain) || legacy_request_domain(raw_domain)
      RequestStore.store[:default_subforem_id]     = Subforem.cached_default_id
      RequestStore.store[:subforem_id]             = Subforem.cached_id_by_domain(domain)
      RequestStore.store[:root_subforem_id]        = Subforem.cached_root_id
      RequestStore.store[:root_subforem_domain]    = Subforem.cached_root_domain
      RequestStore.store[:default_subforem_domain] = Subforem.cached_default_domain
      
      # Cache the current subforem's domain for URL generation
      if RequestStore.store[:subforem_id].present?
        RequestStore.store[:subforem_domain] = Subforem.cached_id_to_domain_hash[RequestStore.store[:subforem_id]]
      end

      # Call Rails (or next middleware) to get the response
      status, headers, body = @app.call(env)

      # POST-PROCESS HEADERS HERE
      # Example logic: if a subforem is found, we do custom cookie manipulation
      if RequestStore.store[:subforem_id].present?
        begin
          subdomain = ForemNative.public_suffix_subdomain_host(request.host)
          if subdomain == :invalid
            Rails.logger.error("Invalid domain: #{request.host}")
            subdomain = false
          elsif subdomain.nil?
            parsed = PublicSuffix.parse(request.host, default_rule: nil)
            subdomain = ForemNative.subforem_subdomain_host(request.host, parsed.sld, parsed.tld)
            subdomain = legacy_subdomain_host?(request.host, parsed) if subdomain.nil?
          end

          if subdomain
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
        rescue PublicSuffix::DomainInvalid
          Rails.logger.error("Invalid domain: #{request.host}")
        end
      end

      # Set Content-Security-Policy header to allow embedding in iframes for all subforems
      headers.delete("X-Frame-Options")
      unless headers["Content-Security-Policy"]&.include?("frame-ancestors")
        allowed_domains = (Subforem.cached_all_domains + [Settings::General.app_domain]).compact.uniq
        origins = allowed_domains.map { |d| "https://#{d}" }
        origins.unshift("'self'") if Rails.env.development?
        headers["Content-Security-Policy"] = "frame-ancestors #{origins.join(' ')}"
      end

      [status, headers, body]
    end

    private

    # A passed_domain with invalid UTF-8 can't name a subforem (and raises in String#blank?), so ignore it.
    def valid_passed_domain(request)
      passed_domain = request.GET["passed_domain"]
      return if passed_domain.is_a?(String) && !passed_domain.valid_encoding?

      passed_domain
    end

    # Handles the domains ForemNative declines (full URLs, paths, non-ASCII, non-Strings).
    def legacy_request_domain(raw_domain)
      parsed_host = begin
        URI.parse(raw_domain).host
      rescue StandardError
        nil
      end
      parsed_host.presence ||
        raw_domain.gsub(%r{\Ahttps?://}, "").split("/").first&.split(":")&.first.presence || raw_domain
    end

    # Handles the hosts and labels ForemNative declines (anything outside [A-Za-z0-9.-]).
    def legacy_subdomain_host?(host, parsed)
      host =~ /^([^.]+)\.#{parsed.sld}\.#{parsed.tld}$/
    end
  end
end
