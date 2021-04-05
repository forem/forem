module Authentication
  class SettingsUpsert
    attr_reader :errors

    def self.call(configs)
      new(configs).call
    end

    def initialize(configs)
      @configs = configs
      @errors = []
    end

    def call
      upsert_configs
      self
    end

    def success?
      @errors.none?
    end

    private

    # NOTE: @citizen428 - This was adapted from Settings::Upsert. I'll see if
    # a pattern for refactoring emerges in the future, but for now I'll leave
    # this as-is.
    def upsert_configs
      @configs.each do |key, value|
        if key == "auth_providers_to_enable"
          update_enabled_providers(value) unless value.class.name != "String"
        elsif value.is_a?(Array) && value.any?
          Settings::Authentication.public_send("#{key}=", value.reject(&:blank?))
        elsif value.present?
          Settings::Authentication.public_send("#{key}=", value.strip)
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors << e.message
        next
      end
    end

    def update_enabled_providers(value)
      enabled_providers = value.split(",").filter_map do |entry|
        entry unless invalid_provider_entry(entry)
      end
      return if email_login_disabled_with_one_or_less_auth_providers(enabled_providers)

      Settings::Authentication.providers = enabled_providers
    end

    def invalid_provider_entry(entry)
      entry.blank? ||
        Authentication::Providers.available.map(&:to_s).exclude?(entry) ||
        provider_keys_missing(entry)
    end

    def provider_keys_missing(entry)
      Settings::Authentication.public_send("#{entry}_key").blank? ||
        Settings::Authentication.public_send("#{entry}_secret").blank?
    end

    def email_login_disabled_with_one_or_less_auth_providers(enabled_providers)
      !Settings::Authentication.allow_email_password_login &&
        enabled_providers.count <= 1
    end
  end
end
