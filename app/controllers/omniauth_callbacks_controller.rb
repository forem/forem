class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  # Rails actionpack only allows POST requests that come with an ORIGIN header
  # that matches `request.base_url`, it raises CSRF exception otherwise.
  # There is no way to allow specific ORIGIN values in order to securely bypass
  # trusted origins (i.e. Apple OAuth) so `protect_from_forgery` is skipped
  # ONLY when it's safe to do so (i.e. ORIGIN == 'https://appleid.apple.com').
  # The hardcoded CSRF check can be found in the method `valid_request_origin?`:
  # https://github.com/rails/rails/blob/901f12212c488f6edfcf6f8ad3230bce6b3d5792/actionpack/lib/action_controller/metal/request_forgery_protection.rb#L449-L459
  protect_from_forgery unless: -> { safe_apple_callback_request? || safe_facebook_callback_request? || safe_google_callback_request? || safe_github_callback_request? }

  # Each available authentication method needs a related action that will be called
  # as a callback on successful redirect from the upstream OAuth provider
  Authentication::Providers.available.each do |provider_name|
    define_method(provider_name) do
      callback_for(provider_name)
    end
  end

  # Callback for third party failures (shared by all providers)
  def failure
    error = request.env["omniauth.error"]
    class_name = error.present? ? error.class.name : ""

    ForemStatsClient.increment(
      "omniauth.failure",
      tags: [
        "class:#{class_name}",
        "message:#{error&.message}",
        "reason:#{error.try(:error_reason)}",
        "type:#{error.try(:error)}",
        "uri:#{error.try(:error_uri)}",
        "provider:#{request.env['omniauth.strategy'].name}",
        "origin:#{request.env['omniauth.strategy.origin']}",
        "params:#{request.env['omniauth.params']}",
      ],
    )

    Honeybadger.notify(error) if error.present?

    super
  end

  def passthru
    redirect_to root_path(signin: "true")
  end

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
  
      # Update tracking and remember the user as usual.
      @user.update_tracked_fields!(request)
      remember_me(@user)
  
      extra_params = request.env["omniauth.params"]
      auth_origin = extra_params["auth_origin"]
      # Check if this is a mobile authentication request.

      if @user.username.downcase.include?("ben")
        Honeybadger.notify("Full omniauth strategy", context: { auth_strategy: request.env["omniauth.strategy"].to_s })
        Honeybadger.notify("Auth payload", context: { auth_payload: auth_payload })
      end

      user_agent = request.user_agent

      if ApplicationConfig["AUTH_TEST_USER_IDS"].present? && ApplicationConfig["AUTH_TEST_USER_IDS"].split(",").include?(@user.id.to_s)
        token = generate_auth_token(@user)
        test_path = ApplicationConfig["AUTH_TEST_USER_REDIRECT_PATH"] || "/menu"
        redirect_to "#{test_path}?jwt=#{token}"
      elsif (auth_payload["provider"].to_s.include?("google") && %w[navbar_basic profile].exclude?(cta_variant)) || user_agent == "ForemWebView/1" || @user.email&.start_with?("bendhalpern")
          # Generate the token the app will use.
        # (Replace the following with your actual token generation logic.)
        token = generate_auth_token(@user)

        if @user.username.downcase.include?("ben")
          Honeybadger.notify("Token path", context: { token: token, username: @user.username })
        end
  
  
        # Render a minimal HTML page that redirects via a custom scheme.
        render html: <<-HTML.html_safe
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="utf-8">
              <title>Authenticating...</title>
              <script type="text/javascript">
                (function() {
                  // Redirect to the custom URL scheme to bring the user back to the app.
                  window.location.href = "forem://auth?token=#{token}";
                  // After a short delay, try to close this window.
                  setTimeout(function() { window.close(); }, 1500);
                })();
              </script>
            </head>
            <body>
              <p>Signing you in…</p>
            </body>
          </html>
        HTML
      else

        if @user.username.downcase.include?("ben")
          Honeybadger.notify("Standard path", context: { username: @user.username })
        end
        # Standard behavior for non-mobile requests.
        sign_in_and_redirect(@user, event: :authentication)
      end
    elsif user_persisted_and_valid?
      redirect_to confirm_email_path(email: @user.email)
    else
      # Handle error conditions.
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

    Honeybadger.notify(e)

    redirect_to root_path
  rescue StandardError => e
    Honeybadger.notify(e)
    flash[:alert] = I18n.t("omniauth_callbacks_controller.log_in_error", e: e)
    redirect_to new_user_registration_url
  end
  

  def user_persisted_and_valid?
    @user.persisted? && @user.valid?
  end

  # We only bypass CSRF checks on Apple callback path & Apple trusted ORIGIN
  def safe_apple_callback_request?
    trusted_origin = Authentication::Providers::Apple::TRUSTED_CALLBACK_ORIGIN
    request.fullpath == Authentication::Providers::Apple::CALLBACK_PATH &&
      request.headers["ORIGIN"] == trusted_origin
  end

  def safe_facebook_callback_request?
    trusted_origin = "https://m.facebook.com"
    facebook_callback_path = "/users/auth/facebook/callback"
    return false unless request&.fullpath&.start_with?(facebook_callback_path)
    
    # Try request.origin first, then fallback to referer.
    origin = request.origin.presence || request.referer
    origin && origin.start_with?(trusted_origin)
  end

  def safe_google_callback_request?
    trusted_origin = "https://accounts.google.com"
    google_callback_path = "/users/auth/google_oauth2/callback"
    return false unless request&.fullpath&.start_with?(google_callback_path)
    
    # Try request.origin first, then fallback to referer.
    origin = request.origin.presence || request.referer
    origin && origin.start_with?(trusted_origin)
  end

  def safe_github_callback_request?
    trusted_origin = "https://github.com"
    github_callback_path = "/users/auth/github/callback"
    return false unless request&.fullpath&.start_with?(github_callback_path)

    # Try request.origin first, then fallback to referer.
    origin = request.origin.presence || request.referer
    origin && origin.start_with?(trusted_origin)
  end

  def generate_auth_token(user)
    payload = {
      user_id: user.id,
      exp: 5.minutes.from_now.to_i # Token expires in 5 minutes
    }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
