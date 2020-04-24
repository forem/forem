module Authentication
  module Providers
    # Retrieves a provider that is both available and enabled
    def self.get!(provider_name)
      name = provider_name.to_s.titleize

      "Authentication::Providers::#{name}".safe_constantize.tap do |klass|
        unless klass
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
      end
    end

    # Returns available providers
    def self.available
      # as providers are lazily loaded, we need to load them all
      # for .subclasses to work correctly
      providers_path = Rails.root.join(
        "app/services/authentication/providers/*.rb",
      ).cleanpath
      Dir[providers_path].each { |file| load(file) }

      Authentication::Providers::Provider.subclasses.map do |subclass|
        subclass.name.demodulize.downcase.to_sym
      end.sort
    end

    # Returns enabled providers
    # TODO: [thepracticaldev/oss] ideally this should be "available - disabled"
    # we can get there once we have feature flags
    def self.enabled
      SiteConfig.authentication_providers.map(&:to_sym).sort
    end

    # Returns true if a provider is enabled, false otherwise
    def self.enabled?(provider_name)
      enabled.include?(provider_name.to_sym)
    end
  end
end
