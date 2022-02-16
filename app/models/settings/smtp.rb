module Settings
  class SMTP < Base
    self.table_name = :settings_smtp

    OPTIONS = %i[address port authentication user_name password domain].freeze

    setting :address, type: :string, default: ApplicationConfig["SMTP_ADDRESS"].presence
    setting :authentication, type: :string, default: ApplicationConfig["SMTP_AUTHENTICATION"].presence,
                             validates: { inclusion: %w[plain login cram_md5] }
    setting :domain, type: :string, default: ApplicationConfig["SMTP_DOMAIN"].presence
    setting :password, type: :string, default: ApplicationConfig["SMTP_PASSWORD"].presence
    setting :port, type: :integer, default: ApplicationConfig["SMTP_PORT"].presence || 25
    setting :user_name, type: :string, default: ApplicationConfig["SMTP_USER_NAME"].presence

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
          password: ENV["SENDGRID_API_KEY"],
          domain: ::Settings::General.app_domain
        }
      end
    end
  end
end
