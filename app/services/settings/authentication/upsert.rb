module Settings
  class Authentication
    module Upsert
      attr_reader :errors

      def self.call(settings)
        auth_providers_to_enable = settings.delete("auth_providers_to_enable")
        result = Settings::Upsert.call(settings, ::Settings::Authentication)
        update_enabled_providers(auth_providers_to_enable)
        result
      end

      def self.update_enabled_providers(value)
        return if value.blank?

        enabled_providers = value.split(",").filter_map do |entry|
          entry unless invalid_provider_entry(entry)
        end
        return if email_login_disabled_with_one_or_less_auth_providers(enabled_providers)

        Settings::Authentication.providers = enabled_providers
      end

      def self.invalid_provider_entry(entry)
        entry.blank? ||
          ::Authentication::Providers.available.map(&:to_s).exclude?(entry) ||
          provider_keys_missing(entry)
      end

      def self.provider_keys_missing(entry)
        ::Settings::Authentication.public_send("#{entry}_key").blank? ||
          ::Settings::Authentication.public_send("#{entry}_secret").blank?
      end

      def self.email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
        !::Settings::Authentication.allow_email_password_login &&
          enabled_providers.count <= 1
      end
    end
  end
end
