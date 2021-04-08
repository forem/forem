module DataUpdateScripts
  class MoveAuthenticationSettings
    AUTHENTICATION_SETTINGS = %w[
      allow_email_password_login
      allow_email_password_registration
      apple_client_id
      apple_key_id
      apple_pem
      apple_team_id
      display_email_domain_allow_list_publicly
      facebook_key
      facebook_secret
      github_key
      github_secret
      invite_only_mode
      require_captcha_for_email_password_registration
      twitter_key
      twitter_secret
    ].freeze

    ATTRIBUTES = %i[var value created_at updated_at].freeze

    def run
      return if Settings::Authentication.any?

      SiteConfig.transaction do
        config_relation = SiteConfig.where(var: AUTHENTICATION_SETTINGS)
        config_values = config_relation.pluck(*ATTRIBUTES).map do |values|
          ATTRIBUTES.zip(values).to_h
        end
        Settings::Authentication.insert_all(config_values) if config_values.present?

        # This field has a validation we don't want to skip
        Settings::Authentication.allowed_registration_email_domains =
          SiteConfig.allowed_registration_email_domains

        # This field got renamed so we migrate it explicitly
        Settings::Authentication.providers = SiteConfig.authentication_providers
      end
    end
  end
end
