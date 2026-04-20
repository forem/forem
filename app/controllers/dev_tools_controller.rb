class DevToolsController < ApplicationController
  before_action :ensure_development_environment



  def index
    @users = User.includes(:roles).order(created_at: :desc).limit(100)
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
