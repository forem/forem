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

  def available_providers_array
    Authentication::Providers.available.map(&:to_s)
  end

  def forem_creator_flow_enabled?
    FeatureFlag.enabled?(:creator_onboarding) && waiting_on_first_user?
  end

  def waiting_on_first_user?
    SiteConfig.waiting_on_first_user
  end

  def invite_only_mode_or_no_enabled_auth_options
    SiteConfig.invite_only_mode ||
      (authentication_enabled_providers.none? && !SiteConfig.allow_email_password_registration)
  end

  def tooltip_class_on_auth_provider_enablebtn
    invite_only_mode_or_no_enabled_auth_options ? "crayons-tooltip" : ""
  end

  def disabled_attr_on_auth_provider_enablebtn
    invite_only_mode_or_no_enabled_auth_options ? "disabled" : ""
  end

  def tooltip_text_email_or_auth_provider_btns
    if invite_only_mode_or_no_enabled_auth_options
      "You cannot do this until you disable Invite Only Mode"
    else
      ""
    end
  end
end
