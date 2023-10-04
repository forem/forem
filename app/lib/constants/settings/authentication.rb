module Constants
  module Settings
    module Authentication
      def self.details
        {
          allowed_registration_email_domains: {
            description: I18n.t("lib.constants.settings.authentication.allowed.description"),
            placeholder: I18n.t("lib.constants.settings.authentication.allowed.placeholder")
          },
          apple_client_id: {
            description: I18n.t("lib.constants.settings.authentication.apple_client.description"),
            placeholder: "com.example.app"
          },
          apple_team_id: {
            description: I18n.t("lib.constants.settings.authentication.apple_team.description"),
            placeholder: ""
          },
          apple_key_id: {
            description: I18n.t("lib.constants.settings.authentication.apple_key.description"),
            placeholder: ""
          },
          apple_pem: {
            description: I18n.t("lib.constants.settings.authentication.apple_pem.description"),
            placeholder: "-----BEGIN PRIVATE KEY-----\nMIGTAQrux...QPe8Yb\n-----END PRIVATE KEY-----\\n"
          },
          blocked_registration_email_domains: {
            description: I18n.t("lib.constants.settings.authentication.blocked.description"),
            placeholder: "seo-hunt.com"
          },
          display_email_domain_allow_list_publicly: {
            description: I18n.t("lib.constants.settings.authentication.display_list.description")
          },
          facebook_key: {
            description: I18n.t("lib.constants.settings.authentication.facebook_key.description"),
            placeholder: ""
          },
          facebook_secret: {
            description: I18n.t("lib.constants.settings.authentication.facebook_secret.description"),
            placeholder: ""
          },
          forem_key: {
            description: I18n.t("lib.constants.settings.authentication.forem_key.description"),
            placeholder: ""
          },
          forem_secret: {
            description: I18n.t("lib.constants.settings.authentication.forem_secret.description"),
            placeholder: ""
          },
          github_key: {
            description: I18n.t("lib.constants.settings.authentication.github_key.description"),
            placeholder: ""
          },
          github_secret: {
            description: I18n.t("lib.constants.settings.authentication.github_secret.description"),
            placeholder: ""
          },
          google_oauth2_key: {
            description: I18n.t("lib.constants.settings.authentication.google_key.description"),
            placeholder: ""
          },
          google_oauth2_secret: {
            description: I18n.t("lib.constants.settings.authentication.google_secret.description"),
            placeholder: ""
          },
          invite_only_mode: {
            description: I18n.t("lib.constants.settings.authentication.invite_only.description"),
            placeholder: ""
          },
          new_user_status: {
            description: I18n.t("lib.constants.settings.authentication.new_user_status.description"),
            placeholder: I18n.t("lib.constants.settings.authentication.new_user_status.placeholder")
          },
          recaptcha_site_key: {
            description: I18n.t("lib.constants.settings.authentication.recaptcha_site.description"),
            placeholder: I18n.t("lib.constants.settings.authentication.recaptcha_site.placeholder")
          },
          recaptcha_secret_key: {
            description: I18n.t("lib.constants.settings.authentication.recaptcha_secret.description"),
            placeholder: I18n.t("lib.constants.settings.authentication.recaptcha_secret.placeholder")
          },
          require_captcha_for_email_password_registration: {
            description: I18n.t("lib.constants.settings.authentication.require_recaptcha.description"),
            placeholder: ""
          },
          twitter_key: {
            description: I18n.t("lib.constants.settings.authentication.twitter_key.description"),
            placeholder: ""
          },
          twitter_secret: {
            description: I18n.t("lib.constants.settings.authentication.twitter_secret.description"),
            placeholder: ""
          },
          providers: {
            description: I18n.t("lib.constants.settings.authentication.providers.description"),
            placeholder: ""
          }
        }
      end
    end
  end
end
