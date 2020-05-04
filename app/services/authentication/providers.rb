# We require all authentication modules to make sure providers
# are correctly preloaded both in development and in production and
# ready to be used when needed at runtime
Dir[Rails.root.join("app/services/authentication/**/*.rb")].each do |f|
  require_dependency(f)
end

module Authentication
  module Providers
    # Retrieves a provider that is both available and enabled
    def self.get!(provider_name)
      name = provider_name.to_s.titleize

      unless available?(provider_name)
        raise(
          ::Authentication::Errors::ProviderNotFound,
          "Provider #{name} is not available!",
        )
      end

      unless enabled?(provider_name)
        raise(
          ::Authentication::Errors::ProviderNotEnabled,
          "Provider #{name} is not enabled!",
        )
      end

      Authentication::Providers.const_get(name)
    end

    def self.available
      Authentication::Providers::Provider.subclasses.map do |subclass|
        subclass.name.demodulize.downcase.to_sym
      end.sort
    end

    def self.available?(provider_name)
      Authentication::Providers.const_defined?(provider_name.to_s.titleize)
    end

    # Returns enabled providers
    # TODO: [thepracticaldev/oss] ideally this should be "available - disabled"
    # we can get there once we have feature flags
    def self.enabled
      SiteConfig.authentication_providers.map(&:to_sym).sort
    end

    def self.enabled?(provider_name)
      enabled.include?(provider_name.to_sym)
    end
  end
end
