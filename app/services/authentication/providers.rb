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

      unless Authentication::Providers.const_defined?(name)
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

    # Returns available providers
    def self.available
      # the magic is done in <config/initializers/authentication_providers.rb>
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

    # Returns the authentication path for the given provider
    def self.authentication_path(provider_name, params = {})
      Rails.application.routes.url_helpers.public_send(
        "user_#{provider_name}_omniauth_authorize_path", params
      )
    end

    # Returns the sign in URL for the given provider
    def self.sign_in_path(provider_name, params = {})
      url_helpers = Rails.application.routes.url_helpers

      callback_url_helper = "user_#{provider_name}_omniauth_callback_path"
      mandatory_params = {
        callback_url: URL.url(url_helpers.public_send(callback_url_helper))
      }

      authentication_path(provider_name, params.merge(mandatory_params))
    end
  end
end
