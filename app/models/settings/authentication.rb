module Settings
  class Authentication < RailsSettings::Base
    self.table_name = :settings_authentications

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::Authentication.clear_cache
    cache_prefix { "v1" }

    field :allow_email_password_login, type: :boolean, default: true
    field :allow_email_password_registration, type: :boolean, default: false
    field :allowed_registration_email_domains, type: :array, default: %w[], validates: {
      valid_domain_csv: true
    }
    field :apple_client_id, type: :string
    field :apple_key_id, type: :string
    field :apple_pem, type: :string
    field :apple_team_id, type: :string
    field :display_email_domain_allow_list_publicly, type: :boolean, default: false
    field :facebook_key, type: :string
    field :facebook_secret, type: :string
    field :github_key, type: :string, default: ApplicationConfig["GITHUB_KEY"]
    field :github_secret, type: :string, default: ApplicationConfig["GITHUB_SECRET"]
    field :invite_only_mode, type: :boolean, default: false
    field :providers, type: :array, default: %w[]
    field :require_captcha_for_email_password_registration, type: :boolean, default: false
    field :twitter_key, type: :string, default: ApplicationConfig["TWITTER_KEY"]
    field :twitter_secret, type: :string, default: ApplicationConfig["TWITTER_SECRET"]

    # Google ReCATPCHA keys
    field :recaptcha_site_key, type: :string, default: ApplicationConfig["RECAPTCHA_SITE"]
    field :recaptcha_secret_key, type: :string, default: ApplicationConfig["RECAPTCHA_SECRET"]

    # Apple uses different keys than the usual `PROVIDER_NAME_key` or
    # `PROVIDER_NAME_secret` so these will help the generalized authentication
    # code to work, i.e. https://github.com/forem/forem/blob/master/app/helpers/authentication_helper.rb#L26-L29
    def self.apple_key
      return unless apple_client_id.present? && apple_key_id.present? &&
        apple_pem.present? && apple_team_id.present?

      "present"
    end
    singleton_class.alias_method(:apple_secret, :apple_key)
  end
end
