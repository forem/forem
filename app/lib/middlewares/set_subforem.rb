module Middlewares
class SetSubforem
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      # If you have a dev param or something similar,
      # you'd read request.params[:passed_domain] as well
      domain = request.params["passed_domain"].presence || request.host

      RequestStore.store[:default_subforem_id]    = Subforem.cached_default_id
      RequestStore.store[:subforem_id]            = Subforem.cached_id_by_domain(domain)
      RequestStore.store[:root_subforem_id]       = Subforem.cached_root_id
      RequestStore.store[:root_subforem_domain]   = Subforem.cached_root_domain
      RequestStore.store[:default_subforem_domain]= Subforem.cached_default_domain

      ## Clean subdomain
      subdomain_regexp = /^([^.]+)\.example\.com$/

      if request.host =~ subdomain_regexp
        # Overwrite cookie with an expired one if it’s set on the subdomain.
        Rack::Utils.delete_cookie_header!(
          headers,
          ApplicationConfig["SESSION_KEY"],
          domain: request.host
        )
      end  

      @app.call(env)
    end
  end
end