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

  def authentication_enabled_providers_for_user(user = current_user)
    Authentication::Providers.enabled_for_user(user)
  end

  def recaptcha_configured_and_enabled?
    SiteConfig.recaptcha_secret_key.present? &&
      SiteConfig.recaptcha_site_key.present? &&
      SiteConfig.require_captcha_for_email_password_registration
  end

  def forem_creator_flow_enabled?
    Flipper.enabled?(:creator_onboarding) && waiting_on_first_user?
  end

  def waiting_on_first_user?
    SiteConfig.waiting_on_first_user
  end
end
