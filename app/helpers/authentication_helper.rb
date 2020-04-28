module AuthenticationHelper
  def authentication_provider(provider_name)
    Authentication::Providers.get!(provider_name)
  end

  def authentication_enabled_providers
    Authentication::Providers.enabled.map do |provider_name|
      Authentication::Providers.get!(provider_name)
    end
  end

  def authentication_path(provider_name, params = {})
    Authentication::Providers.authentication_path(provider_name, params)
  end

  def sign_in_path(provider_name, params = {})
    Authentication::Providers.sign_in_path(provider_name, params)
  end
end
