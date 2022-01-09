module Constants
  module Settings
    module Authentication
      def self.details
        {
          allowed_registration_email_domains: {
            description: I18n.t("lib.constants.settings.authentication.restrict_registration_to_o"),
            placeholder: I18n.t("lib.constants.settings.authentication.dev_to_forem_com_codenewbi")
          },
          apple_client_id: {
            description: I18n.t("lib.constants.settings.authentication.the_app_bundle_code_for_th"),
            placeholder: "com.example.app"
          },
          apple_team_id: {
            description: I18n.t("lib.constants.settings.authentication.the_team_id_of_your_apple"),
            placeholder: ""
          },
          apple_key_id: {
            description: I18n.t("lib.constants.settings.authentication.the_key_id_from_the_authen"),
            placeholder: ""
          },
          apple_pem: {
            description: I18n.t("lib.constants.settings.authentication.the_pem_key_from_the_authe"),
            placeholder: "-----BEGIN PRIVATE KEY-----\nMIGTAQrux...QPe8Yb\n-----END PRIVATE KEY-----\\n"
          },
          blocked_registration_email_domains: {
            description: I18n.t("lib.constants.settings.authentication.blocked_registration"),
            placeholder: "seo-hunt.com"
          },
          display_email_domain_allow_list_publicly: {
            description: I18n.t("lib.constants.settings.authentication.do_you_want_to_display_the")
          },
          facebook_key: {
            description: I18n.t("lib.constants.settings.authentication.the_app_id_portion_of_the"),
            placeholder: ""
          },
          facebook_secret: {
            description: I18n.t("lib.constants.settings.authentication.the_app_secret_portion_of"),
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
            description: I18n.t("lib.constants.settings.authentication.the_client_id_portion_of_t"),
            placeholder: ""
          },
          github_secret: {
            description: I18n.t("lib.constants.settings.authentication.the_client_secret_portion"),
            placeholder: ""
          },
          invite_only_mode: {
            description: I18n.t("lib.constants.settings.authentication.only_users_invited_by_emai"),
            placeholder: ""
          },
          recaptcha_site_key: {
            description: I18n.t("lib.constants.settings.authentication.add_the_site_key_for_googl"),
            placeholder: I18n.t("lib.constants.settings.authentication.what_is_the_google_recaptc")
          },
          recaptcha_secret_key: {
            description: I18n.t("lib.constants.settings.authentication.add_the_secret_key_for_goo"),
            placeholder: I18n.t("lib.constants.settings.authentication.what_is_the_google_recaptc2")
          },
          require_captcha_for_email_password_registration: {
            description: I18n.t("lib.constants.settings.authentication.people_will_be_required_to"),
            placeholder: ""
          },
          twitter_key: {
            description: I18n.t("lib.constants.settings.authentication.the_api_key_portion_of_con"),
            placeholder: ""
          },
          twitter_secret: {
            description: I18n.t("lib.constants.settings.authentication.the_api_secret_key_portion"),
            placeholder: ""
          },
          providers: {
            description: I18n.t("lib.constants.settings.authentication.how_can_users_sign_in"),
            placeholder: ""
          }
        }
      end
    end
  end
end
