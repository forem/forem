module AuthenticationHelper
  def authentication_provider(provider_name)
    Authentication::Providers.get!(provider_name)
  end

  def authentication_available_providers
    Authentication::Providers.available.map do |provider_name|
      Authentication::Providers.const_get(provider_name.to_s.titleize)
    end
  end

  def authentication_enabled_providers
    Authentication::Providers.enabled.map do |provider_name|
      Authentication::Providers.get!(provider_name)
    end
  end

  def current_user_authentication_enabled_providers
    providers = Authentication::Providers.enabled & current_user.identities.pluck(:provider).map(&:to_sym)
    providers.sort.map do |provider_name|
      Authentication::Providers.get!(provider_name)
    end
  end
end
