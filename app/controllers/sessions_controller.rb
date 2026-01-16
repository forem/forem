class SessionsController < Devise::SessionsController
  before_action :skip_session_verification, only: [:destroy]
  
  def destroy
    if user_signed_in?
      user_id = current_user.id
      Rails.logger.info "[LOGOUT] User #{user_id} logging out on #{request.host}"
      
      # Mark user as globally logged out in database
      current_user.update_columns(current_sign_in_at: nil, current_sign_in_ip: nil)
      
      # Delete remember token cookies on shared domain
      root_domain = Settings::General.app_domain
      cookies.delete(:remember_user_token, domain: ".#{root_domain}")
      cookies.delete(:forem_user_signed_in, domain: ".#{root_domain}")
      cookies.delete(:remember_user_token)
      cookies.delete(:forem_user_signed_in)
      
      Rails.logger.info "[LOGOUT] User #{user_id} cookies deleted, calling Devise sign_out"
    end
    
    # Devise handles session clearing and redirect
    super
  end

  private

  def skip_session_verification
    @skip_session_verification = true
  end
end
