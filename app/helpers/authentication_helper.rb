module AuthenticationHelper
  def authentication_provider(provider_name)
    Authentication::Providers.get!(provider_name)
  end

  def authentication_available_providers
    Authentication::Providers.available_providers
  end

  def authentication_enabled_providers
    Authentication::Providers.enabled.map do |provider_name|
      Authentication::Providers.get!(provider_name)
    end
  end

  def authentication_provider_enabled?(provider_name)
    authentication_enabled_providers.include?(provider_name)
  end

  def authentication_enabled_providers_for_user(user = current_user)
    Authentication::Providers.enabled_for_user(user)
  end

  def signed_up_with(user = current_user)
    providers = Authentication::Providers.enabled_for_user(user)

    # If the user did not authenticate with any provider, they signed up with an email.
    # rubocop:disable Layout/LineLength
    auth_method = providers.any? ? providers.map(&:official_name).to_sentence : I18n.t("helpers.authentication_helper.email_password")
    demonstrative = providers.size > 1 ? I18n.t("helpers.authentication_helper.any_of_those") : I18n.t("helpers.authentication_helper.that")
    link = new_magic_link_url(email: user.email)
    # rubocop:enable Layout/LineLength

    I18n.t("helpers.authentication_helper.reminder", method: auth_method, dem: demonstrative, link: link)
  end

  def available_providers_array
    Authentication::Providers.available.map(&:to_s)
  end

  def waiting_on_first_user?
    Settings::General.waiting_on_first_user
  end

  def invite_only_mode_or_no_enabled_auth_options
    ForemInstance.invitation_only? ||
      (authentication_enabled_providers.none? &&
       !Settings::Authentication.allow_email_password_registration)
  end

  def tooltip_class_on_auth_provider_enablebtn
    invite_only_mode_or_no_enabled_auth_options ? "crayons-hover-tooltip" : ""
  end

  def disabled_attr_on_auth_provider_enable_btn
    invite_only_mode_or_no_enabled_auth_options ? "disabled" : ""
  end

  def tooltip_text_email_or_auth_provider_btns
    if invite_only_mode_or_no_enabled_auth_options
      I18n.t("helpers.authentication_helper.invite_only")
    else
      ""
    end
  end

  def came_from_sign_up?
    request.referer&.include?(new_user_registration_path)
  end

  # Returns true when a social authentication provider should be displayed in
  # `/enter` page. This method serves the need to comply with platform specific
  # restrictions, such as:
  # - Within mobile apps we must hide social auth providers unless SIWA is enabled
  # - Forem authentication doesn't need to comply with the above (it's the exception)
  def display_social_login?(provider_name = nil)
    return true if Authentication::Providers.enabled.include?(:apple)
    return true if request.user_agent.to_s.match?(/Android/i)
    return true if provider_name == :forem && Authentication::Providers.enabled.include?(:forem)

    # Don't display (return false) if UserAgent includes ForemWebview - iOS only
    request.user_agent.to_s.exclude?("ForemWebView")
  end

  # Display the fallback message (return true) if there is no way to register
  # (on mobile apps). This only happens when all of the following are true:
  # - We're on the "Create account" page
  # - Email+Password registration is disabled
  # - There are no social options enabled
  #    - This happens on mobile apps because of platform specific issues
  def display_registration_fallback?(state)
    state == "new-user" && !Settings::Authentication.allow_email_password_registration && !display_social_login?(:forem)
  end
end
