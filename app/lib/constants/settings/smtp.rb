module Constants
  module Settings
    module SMTP
      def self.details
        {
          address: {
            description: I18n.t("lib.constants.settings.smtp.address.description"),
            placeholder: I18n.t("lib.constants.settings.smtp.address.placeholder")
          },
          port: {
            description: I18n.t("lib.constants.settings.smtp.port.description"),
            placeholder: I18n.t("lib.constants.settings.smtp.port.placeholder")
          },
          authentication: {
            description: I18n.t("lib.constants.settings.smtp.authentication.description"),
            placeholder: I18n.t("lib.constants.settings.smtp.authentication.placeholder")
          },
          user_name: {
            description: I18n.t("lib.constants.settings.smtp.user_name.description"),
            placeholder: ""
          },
          password: {
            description: I18n.t("lib.constants.settings.smtp.password.description"),
            placeholder: ""
          },
          domain: {
            description: I18n.t("lib.constants.settings.smtp.domain.description"),
            placeholder: ""
          },
          from_email_address: {
            description: I18n.t("lib.constants.settings.smtp.from_email.description"),
            placeholder: ""
          },
          reply_to_email_address: {
            description: I18n.t("lib.constants.settings.smtp.reply_to.description"),
            placeholder: ""
          }
        }
      end
    end
  end
end
