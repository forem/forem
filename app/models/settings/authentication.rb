module Settings
  class Authentication < RailsSettings::Base
    self.table_name = :settings_authentications

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::Authentication.clear_cache
    cache_prefix { "v1" }

    # Authentication
    field :allow_email_password_registration, type: :boolean, default: false
    field :allow_email_password_login, type: :boolean, default: true
    field :allowed_registration_email_domains, type: :array, default: %w[], validates: {
      valid_domain_csv: true
    }
    field :display_email_domain_allow_list_publicly, type: :boolean, default: false
    field :require_captcha_for_email_password_registration, type: :boolean, default: false
    field :authentication_providers, type: :array, default: %w[]
    field :invite_only_mode, type: :boolean, default: false
    field :twitter_key, type: :string, default: ApplicationConfig["TWITTER_KEY"]
    field :twitter_secret, type: :string, default: ApplicationConfig["TWITTER_SECRET"]
    field :github_key, type: :string, default: ApplicationConfig["GITHUB_KEY"]
    field :github_secret, type: :string, default: ApplicationConfig["GITHUB_SECRET"]
    field :facebook_key, type: :string
    field :facebook_secret, type: :string
    field :apple_client_id, type: :string
    field :apple_key_id, type: :string
    field :apple_pem, type: :string
    field :apple_team_id, type: :string
  end
end
