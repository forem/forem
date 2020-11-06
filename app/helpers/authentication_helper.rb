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

  def invite_only_mode_or_no_enabled_providers
    SiteConfig.invite_only_mode || authentication_enabled_providers.none?
  end

  def email_login_disabled_and_one_auth_provider_enabled
    !SiteConfig.allow_email_password_login && authentication_enabled_providers.count == 1
  end

  def tooltip_class_on_email_auth_disablebtn
    invite_only_mode_or_no_enabled_providers ? "crayons-tooltip" : ""
  end

  def tooltip_class_on_auth_provider_enablebtn
    SiteConfig.invite_only_mode ? "crayons-tooltip" : ""
  end

  def tooltip_class_on_auth_provider_disablebtn
    email_login_disabled_and_one_auth_provider_enabled ? "crayons-tooltip" : ""
  end

  def disabled_attr_on_email_auth_disablebtn
    invite_only_mode_or_no_enabled_providers ? "disabled" : ""
  end

  def disabled_attr_on_auth_provider_enablebtn
    SiteConfig.invite_only_mode ? "disabled" : ""
  end

  def disabled_attr_on_auth_rpovider_disablebtn
    email_login_disabled_and_one_auth_provider_enabled ? "disabled" : ""
  end

  def tooltip_text_email_or_auth_provider_btns
    if SiteConfig.invite_only_mode
      "You cannot do this until you disable Invite Only Mode"
    elsif authentication_enabled_providers.none? || email_login_disabled_and_one_auth_provider_enabled
      "You cannot do this until you enable at least one other registration option"
    else
      ""
    end
  end
end
