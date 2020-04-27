class EmailAuthorizationsController < ApplicationController
  def verify
    user = User.find_by(username: params[:username])
    raise ActionController::RoutingError, "Not Found" unless user && current_user == user

    email_authorization = user.email_authorizations.order("created_at DESC").first
    raise ActionController::RoutingError, "Not Found" unless email_authorization.confirmation_token == params[:confirmation_token]

    email_authorization.update(verified_at: Time.now.utc)
    redirect_to "/"
  end
end
