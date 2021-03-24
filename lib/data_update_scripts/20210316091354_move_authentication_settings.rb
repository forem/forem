module DataUpdateScripts
  class MoveAuthenticationSettings
    AUTHENTICATION_SETTINGS = %w[
      allow_email_password_login
      allow_email_password_registration
      allowed_registration_email_domains
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
      providers
      require_captcha_for_email_password_registration
      twitter_key
      twitter_secret
    ].freeze

    def run
      SiteConfig.transaction do
        config_relation = SiteConfig.where(var: AUTHENTICATION_SETTINGS)
        config_values = config_relation.pluck(:var, :value).map do |var, value|
          timestamp = Time.current
          { var: var, value: value, created_at: timestamp, updated_at: timestamp }
        end
        Settings::Authentication.insert_all(config_values)

        SiteConfig.where(var: AUTHENTICATION_SETTINGS).destroy_all
      end
    end
  end
end
