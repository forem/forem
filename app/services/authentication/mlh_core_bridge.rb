module Authentication
  # TEMPORARY: MLH "Core" integration bridge.
  #
  # When MLH_OAUTH_BASE_URL is set, MLH sign-in is brokered by MLH Core, which
  # also proxies the MyMLH API on Forem's behalf. Everything Core-specific lives
  # here and in Authentication::ExternalReturn so the integration can be removed
  # in one place once Core speaks standard OIDC third-party initiated login
  # (target_link_uri) instead of the custom continuation round trip.
  #
  # Removal checklist:
  #   - this file and Authentication::ExternalReturn (plus their specs)
  #   - the MlhCoreBridge call in config/initializers/devise.rb
  #   - the ExternalReturn call sites in OmniauthCallbacksController
  #   - MLH_OAUTH_BASE_URL, MLH_API_BASE_URL and FOREM_EXTERNAL_RETURN_* in .env_sample
  #   - "continuation" in config/initializers/filter_parameter_logging.rb
  #   - the gated block in db/seeds.rb
  #   - the Core sections of spec/requests/mlh_oauth_callbacks_spec.rb and
  #     spec/initializers/mlh_omniauth_setup_spec.rb
  module MlhCoreBridge
    # Core only issues these; anything wider is stripped from the request so
    # the authorize call does not fail on an unknown scope.
    PROXIED_SCOPES = %w[public user:read:profile mlh:read:user].freeze

    def self.enabled?
      ENV["MLH_OAUTH_BASE_URL"].present?
    end

    # Points the omniauth-mlh strategy at Core instead of my.mlh.io.
    def self.apply!(strategy)
      if enabled?
        oauth_base = ENV["MLH_OAUTH_BASE_URL"].chomp("/")
        strategy.options[:client_options][:site] = oauth_base
        strategy.options[:client_options][:authorize_url] = "#{oauth_base}/oauth/authorize"
        strategy.options[:client_options][:token_url] = "#{oauth_base}/oauth/token"
        strategy.options[:scope] = strategy.options[:scope].split.intersection(PROXIED_SCOPES).join(" ")
        # Core proxies provider API calls, so Forem must not persist bearer credentials.
        strategy.options[:persist_credentials] = false
      end

      return if ENV["MLH_API_BASE_URL"].blank?

      strategy.options[:client_options][:api_site] = ENV["MLH_API_BASE_URL"].chomp("/")
    end
  end
end
