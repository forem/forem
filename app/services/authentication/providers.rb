module Authentication
  module Providers
    # TODO: [thepracticaldev/oss] raise exception if provider is available but not enabled for this app
    # TODO: [thepracticaldev/oss] add available providers, enabled providers
    def self.get!(provider_name)
      "Authentication::Providers::#{provider_name.titleize}".constantize
    rescue NameError => e
      raise ::Authentication::Errors::ProviderNotFound, e
    end
  end
end
