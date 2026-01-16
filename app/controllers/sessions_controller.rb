class SessionsController < Devise::SessionsController
  def destroy
    if user_signed_in?
      user_id = current_user.id
      Rails.logger.info "[LOGOUT] User #{user_id} logging out on #{request.host}"
      
      # Mark user as globally logged out in database
      current_user.update_columns(current_sign_in_at: nil, current_sign_in_ip: nil)
      
      # Clear session to prevent re-authentication
      reset_session
      
      # Delete remember token cookies on shared domain
      root_domain = Settings::General.app_domain
      cookies.delete(:remember_user_token, domain: ".#{root_domain}")
      cookies.delete(:forem_user_signed_in, domain: ".#{root_domain}")
      cookies.delete(:remember_user_token)
      cookies.delete(:forem_user_signed_in)
      
      # Call Devise's sign_out to clean up Warden
      super
      
      Rails.logger.info "[LOGOUT] User #{user_id} fully logged out"
    end
  end
end
