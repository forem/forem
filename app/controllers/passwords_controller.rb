class PasswordsController < Devise::PasswordsController
  # allow already signed in users to reset their password
  skip_before_action :require_no_authentication

  def new
    super
    session[:referrer] = request.referer
  end

  protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    flash[:global_notice] = I18n.t("devise.passwords.reset_instructions_sent")
    session[:referrer]
  end
end
