class PasswordsController < Devise::PasswordsController
  # allow already signed in users to reset their password
  skip_before_action :require_no_authentication

  def new
    super
    referrer_path = safe_referrer_path(request.referer)
    session[:referrer] = referrer_path if referrer_path.present?
  end

  def update
    super do |resource|
      if resource.errors.empty? && resource.confirmed_at.blank?
        resource.update_column(:confirmed_at, Time.current)
        resource.track!("user_updated")
      end
    end
  end

  protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    flash[:global_notice] = I18n.t("devise.passwords.reset_instructions_sent")
    safe_referrer_path(session.delete(:referrer)) || default_after_sending_reset_password_instructions_path
  end

  def after_resetting_password_path_for(resource)
    return new_session_path(resource_name) unless resource_class.sign_in_after_reset_password

    bypass_sign_in(resource)
    remember_me(resource) if cookies[:remember_user_token].present?
    stored_location_for(resource)
    flash[:settings_notice] = flash.delete(:notice).presence || I18n.t("devise.passwords.updated")
    user_settings_path(:account)
  end

  def assert_reset_token_passed
    return if params[:reset_password_token].present?

    if user_signed_in?
      flash[:error] = I18n.t("devise.passwords.no_token")
      redirect_to user_settings_path(:account)
    else
      super
    end
  end

  private

  def default_after_sending_reset_password_instructions_path
    user_signed_in? ? user_settings_path(:account) : sign_up_path
  end

  def safe_referrer_path(referrer)
    return if referrer.blank?

    uri = URI.parse(referrer)
    return if uri.host.present? && uri.host != request.host
    return if uri.path.blank? || uri.path.start_with?("/users/password")

    uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
  rescue URI::InvalidURIError
    nil
  end
end
