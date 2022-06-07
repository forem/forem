module Settings
  class SMTP < Base
    self.table_name = :settings_smtp
    AUTHENTICATION_METHODS = %w[plain login cram_md5].freeze

    setting :address, type: :string, default: ApplicationConfig["SMTP_ADDRESS"].presence
    setting :authentication, type: :string, default: ApplicationConfig["SMTP_AUTHENTICATION"].presence,
                             validates: { inclusion: AUTHENTICATION_METHODS }
    setting :domain, type: :string, default: ApplicationConfig["SMTP_DOMAIN"].presence
    setting :password, type: :string, default: ApplicationConfig["SMTP_PASSWORD"].presence
    setting :port, type: :integer, default: ApplicationConfig["SMTP_PORT"].presence || 25
    setting :user_name, type: :string, default: ApplicationConfig["SMTP_USER_NAME"].presence
    setting :from_email_address, type: :string, default: ApplicationConfig["DEFAULT_EMAIL"].presence,
                                 validates: { email: true, allow_blank: true }
    setting :reply_to_email_address, type: :string, default: ApplicationConfig["DEFAULT_EMAIL"].presence,
                                     validates: { email: true, allow_blank: true }

    class << self
      def settings
        if provided_minimum_settings?
          custom_provider_settings
        else
          fallback_sendgrid_settings
        end
      end

      def provided_minimum_settings?
        address.present? && user_name.present? && password.present?
      end

      private

      def custom_provider_settings
        to_h
      end

      def fallback_sendgrid_settings
        {
          address: "smtp.sendgrid.net",
          port: 587,
          authentication: :plain,
          user_name: "apikey",
          password: ENV.fetch("SENDGRID_API_KEY", nil),
          domain: ::Settings::General.app_domain
        }
      end
    end
  end
end
