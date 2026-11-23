class SessionsController < Devise::SessionsController
  def destroy
    if user_signed_in?
      Authentication::AuthToken.revoke_for_user!(current_user.id)
      current_user.update_columns(current_sign_in_at: nil, current_sign_in_ip: nil)
      cookies.delete(:forem_user_signed_in, domain: request.host)
      super
    end
  end
end
