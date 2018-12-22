class ApiSecretsController < ApplicationController
  before_action :set_user

  def create
    @secret = ApiSecret.new(description: params[:description], user_id: @user.id)
    if @secret.save
      flash[:notice] = "Your access token has been generated."
      redirect_back(fallback_location: root_path)
    end
  end

  def destroy; end

  private

  def set_user
    @user = current_user
  end
end
