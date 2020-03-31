class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  LEGACY_COOKIE_NAME = "_PracticalDeveloper_session".freeze

  # Don't need a policy for this since this is our sign up/in route
  include Devise::Controllers::Rememberable

  def twitter
    callback_for("twitter")
  end

  def github
    callback_for("github")
  end

  def failure
    Rails.logger.error "Omniauth failure",
                       omniauth_failure: {
                         error: request.env["omniauth.error"]&.inspect,
                         error_type: request.env["omniauth.error.type"].to_s,
                         auth: request.env["omniauth.auth"],
                         provider: request.env["omniauth.strategy"].to_s,
                         cookie: request.env["rack.request.cookie_hash"]
                       }
    super
  end

  private

  def callback_for(provider)
    cta_variant = request.env["omniauth.params"]["state"].to_s
    @user = AuthorizationService.new(request.env["omniauth.auth"], current_user, cta_variant).get_user

    if persisted_and_valid?
      # delete legacy session based cookie once the user has logged in again
      request.cookie_jar.delete(LEGACY_COOKIE_NAME) if request.cookies[LEGACY_COOKIE_NAME]

      remember_me(@user)
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
    elsif persisted_but_username_taken?
      redirect_to "/settings?state=previous-registration"
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]
      user_errors = @user.errors.full_messages
      Rails.logger.error "Log in error: sign in failed. username: #{@user.username} - email: #{@user.email}"
      Rails.logger.error "Log in error: auth data hash - #{request.env['omniauth.auth']}"
      Rails.logger.error "Log in error: auth data hash - #{request.env['omniauth.error']&.inspect}"
      Rails.logger.error "Log in error: user_errors: #{user_errors}"
      flash[:alert] = user_errors
      redirect_to new_user_registration_url
    end
  rescue StandardError => e
    Rails.logger.error "Log in error: #{e}"
    Rails.logger.error "Log in error: auth data hash - #{request.env['omniauth.auth']}"
    Rails.logger.error "Log in error: auth data hash - #{request.env['omniauth.error']&.inspect}"
    flash[:alert] = "Log in error: #{e}"
    redirect_to new_user_registration_url
  end

  def persisted_and_valid?
    @user.persisted? && @user.valid?
  end

  def persisted_but_username_taken?
    @user.persisted? && @user.errors.full_messages.join(", ").include?("username has already been taken")
  end
end
