class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  # Bypass CSRF only if the request is safe (Apple or Facebook).
  protect_from_forgery unless: -> { safe_apple_callback_request? || safe_facebook_callback_request? }

  Authentication::Providers.available.each do |provider_name|
    define_method(provider_name) do
      callback_for(provider_name)
    end
  end

  # ... (failure and passthru methods remain unchanged)

  private

  def callback_for(provider)
    auth_payload = request.env["omniauth.auth"]
    cta_variant = request.env["omniauth.params"]["state"].to_s

    @user = Authentication::Authenticator.call(
      auth_payload,
      current_user: current_user,
      cta_variant: cta_variant,
    )

    if user_persisted_and_valid? && @user.confirmed?
      set_flash_message(:notice, :success, kind: provider.to_s.titleize) if is_navigational_format?
      @user.update_tracked_fields!(request)
      remember_me(@user)
      sign_in_and_redirect(@user, event: :authentication)
    elsif user_persisted_and_valid?
      redirect_to confirm_email_path(email: @user.email)
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]
      user_errors = @user.errors.full_messages

      Honeybadger.context({
        username: @user.username,
        user_id: @user.id,
        auth_data: request.env["omniauth.auth"],
        auth_error: request.env["omniauth.error"].inspect,
        user_errors: user_errors
      })
      Honeybadger.notify("Omniauth log in error")
      flash[:alert] = user_errors
      redirect_to new_user_registration_url
    end
  rescue ::Authentication::Errors::PreviouslySuspended, ::Authentication::Errors::SpammyEmailDomain => e
    flash[:global_notice] = e.message
    redirect_to root_path
  rescue StandardError => e
    Honeybadger.notify(e)
    flash[:alert] = I18n.t("omniauth_callbacks_controller.log_in_error", e: e)
    redirect_to new_user_registration_url
  end

  def user_persisted_and_valid?
    @user.persisted? && @user.valid?
  end

  # Bypass for Apple OAuth requests.
  def safe_apple_callback_request?
    trusted_origin = Authentication::Providers::Apple::TRUSTED_CALLBACK_ORIGIN
    request.fullpath == Authentication::Providers::Apple::CALLBACK_PATH &&
      request.headers["ORIGIN"] == trusted_origin
  end

  # New method for bypassing CSRF for Facebook OAuth requests.
  def safe_facebook_callback_request?
    # Define the trusted ORIGIN for Facebook.
    trusted_origin = "https://www.facebook.com" # Verify if this is the correct value.
    # Define the expected callback path for Facebook.
    facebook_callback_path = "/users/auth/facebook/callback"
    # Check if the fullpath starts with the expected callback path and the ORIGIN matches.
    request.fullpath.start_with?(facebook_callback_path) &&
      request.headers["ORIGIN"] == trusted_origin
  end
end
