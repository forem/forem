class EmailAuthorizationsController < ApplicationController
  before_action :authenticate_user!

  def verify
    user = User.find_by(username: params[:username])
    raise ActionController::RoutingError, "Not Found" unless current_user == user

    email_authorization = user.email_authorizations.order(created_at: :desc).first
    correct_token = email_authorization.confirmation_token == params[:confirmation_token]
    raise ActionController::RoutingError, "Not Found" unless correct_token

    email_authorization.update(verified_at: Time.current)
    redirect_to root_path
  end
end
