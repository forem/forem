# We require all authentication modules to make sure providers
# are correctly preloaded and ready to be used at this point as the loading
# order is important
require_dependency Rails.root.join("app/services/authentication/providers/provider.rb")

Dir[Rails.root.join("app/services/authentication/**/*.rb")].each do |f|
  require_dependency(f)
end

module Authentication
  module Providers
    # Retrieves a provider that is both available and enabled
    def self.get!(provider_name)
      name = provider_name.to_s.camelize

      unless available?(provider_name)
        raise(
          ::Authentication::Errors::ProviderNotFound,
          I18n.t("services.authentication.providers.not_available", name: name),
        )
      end

      unless enabled?(provider_name)
        raise(
          ::Authentication::Errors::ProviderNotEnabled,
          I18n.t("services.authentication.providers.not_enabled", name: name),
        )
      end

      Authentication::Providers.const_get(name)
    end

    def self.available
      Authentication::Providers::Provider.subclasses.map do |subclass|
        subclass.name.demodulize.underscore.downcase.to_sym
      end.sort
    end

    def self.available_providers
      Authentication::Providers::Provider.subclasses.sort_by(&:name)
    end

    def self.available?(provider_name)
      Authentication::Providers.const_defined?(provider_name.to_s.camelize)
    end

    # Returns enabled providers
    # TODO: [@forem/oss] ideally this should be "available - disabled"
    # we can get there once we have feature flags
    def self.enabled
      return [] if ForemInstance.invitation_only?

      Settings::Authentication.providers.map(&:to_sym)
    end

    def self.enabled_for_user(user)
      return [] unless user

      providers = enabled & user.identities.pluck(:provider).map(&:to_sym)
      providers.sort.map do |provider_name|
        get!(provider_name)
      end
    end

    def self.enabled?(provider_name)
      enabled.include?(provider_name.to_sym)
    end

    def self.username_fields
      Authentication::Providers::Provider.subclasses.map(&:user_username_field).sort
    end
  end
end
