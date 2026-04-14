class DevToolsController < ApplicationController
  before_action :ensure_development_environment
  skip_before_action :verify_authenticity_token, only: [:sign_in_as]



  def index
    @users = User.order(created_at: :desc).limit(100)
  end

  def sign_in_as
    user = User.find(params[:user_id])
    sign_in(user, bypass: true)
    redirect_to "/", notice: "Successfully assumed identity of #{user.username} (Development Mode)"
  end

  private

  def ensure_development_environment
    head :forbidden unless Rails.env.development?
  end
end
