class EmailAuthorizationsController < ApplicationController
  before_action :authenticate_user!

  def verify
    user = User.find_by(username: params[:username])
    raise ActionController::RoutingError, "Not Found" unless current_user == user

    email_authorization = user.email_authorizations.order("created_at DESC").first
    raise ActionController::RoutingError, "Not Found" unless email_authorization.confirmation_token == params[:confirmation_token]

    email_authorization.update(verified_at: Time.current)
    redirect_to root_path
  end
end
