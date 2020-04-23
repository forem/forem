class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Don't need a policy for this since this is our sign up/in route
  include Devise::Controllers::Rememberable

  # Called upon successful redirect from Twitter
  def twitter
    callback_for(:twitter)
  end

  # Called upon successful redirect from GitHub
  def github
    callback_for(:github)
  end

  # Callback for third party failures (shared by all providers)
  def failure
    error = request.env["omniauth.error"]
    class_name = error.present? ? error.class.name : ""

    DatadogStatsClient.increment(
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

    super
  end

  private

  # TODO: [thepracticaldev/oss] investigate if there's a way to simplify this
  # by using Devise+OmniAuth builtin integration
  # <https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview>
  def callback_for(provider)
    cta_variant = request.env["omniauth.params"]["state"].to_s
    @user = Authentication::Authenticator.call(
      request.env["omniauth.auth"],
      current_user: current_user,
      cta_variant: cta_variant,
    )

    if user_persisted_and_valid?
      remember_me(@user)

      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?

      sign_in_and_redirect(@user, event: :authentication)
    # NOTE: I can't find a way to test this path
    # as `User` will assign a temporary username if the username already exists
    # see https://github.com/thepracticaldev/dev.to/blob/27131f6f420df347a467f8e9afc84a6af2fcb13a/app/models/user.rb#L532-L555
    elsif user_persisted_but_username_taken?
      redirect_to "/settings?state=previous-registration"
    # NOTE: I can't find a way to test this path
    # as `Authentication::Authenticator.call` invokes `User.save!` which will
    # raise errors for a validation error.
    # In the past we had 1 path (update_user) which would have ended up
    # here in case of validation errors, see:
    # https://github.com/thepracticaldev/dev.to/blob/80737b540453afe8775128cb37bd379b7c09c7e8/app/services/authorization_service.rb#L77
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"]

      user_errors = @user.errors.full_messages

      Rails.logger.error("Log in error: sign in failed. username: #{@user.username} - email: #{@user.email}")
      Rails.logger.error("Log in error: auth data hash - #{request.env['omniauth.auth']}")
      Rails.logger.error("Log in error: auth data hash - #{request.env['omniauth.error']&.inspect}")
      Rails.logger.error("Log in error: user_errors: #{user_errors}")

      flash[:alert] = user_errors
      redirect_to new_user_registration_url
    end
  rescue StandardError => e
    Rails.logger.error("Log in error: #{e}")
    Rails.logger.error("Log in error: auth data hash - #{request.env['omniauth.auth']}")
    Rails.logger.error("Log in error: auth data hash - #{request.env['omniauth.error']&.inspect}")

    flash[:alert] = "Log in error: #{e}"
    redirect_to new_user_registration_url
  end

  def user_persisted_and_valid?
    @user.persisted? && @user.valid?
  end

  def user_persisted_but_username_taken?
    @user.persisted? && @user.errors.full_messages.join(", ").include?("username has already been taken")
  end
end
