module Settings
  class Authentication < Base
    self.table_name = :settings_authentications

    setting :allow_email_password_login, type: :boolean, default: true
    setting :allow_email_password_registration, type: :boolean, default: false
    setting :allowed_registration_email_domains, type: :array, default: %w[], validates: {
      valid_domain_csv: true
    }
    setting :apple_client_id, type: :string
    setting :apple_key_id, type: :string
    setting :apple_pem, type: :string
    setting :apple_team_id, type: :string
    setting :display_email_domain_allow_list_publicly, type: :boolean, default: false
    setting :facebook_key, type: :string
    setting :facebook_secret, type: :string
    setting :github_key, type: :string, default: ApplicationConfig["GITHUB_KEY"]
    setting :github_secret, type: :string, default: ApplicationConfig["GITHUB_SECRET"]
    setting :invite_only_mode, type: :boolean, default: false
    setting :providers, type: :array, default: %w[]
    setting :require_captcha_for_email_password_registration, type: :boolean, default: false
    setting :twitter_key, type: :string, default: ApplicationConfig["TWITTER_KEY"]
    setting :twitter_secret, type: :string, default: ApplicationConfig["TWITTER_SECRET"]

    # Google ReCATPCHA keys
    setting :recaptcha_site_key, type: :string, default: ApplicationConfig["RECAPTCHA_SITE"]
    setting :recaptcha_secret_key, type: :string, default: ApplicationConfig["RECAPTCHA_SECRET"]

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
