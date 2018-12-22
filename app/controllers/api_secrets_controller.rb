class ApiSecretsController < ApplicationController
  before_action :set_user

  def create
    @secret = ApiSecret.new(description: params[:description], user_id: @user.id)
    if @secret.save
      flash[:notice] = "Your access token has been generated."
      redirect_back(fallback_location: root_path)
    end
  end

  def destroy
    @secret = ApiSecret.find_by_id(params[:id])
    if @secret.destroy
      flash[:notice] = "Your access token has been destroyed."
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def set_user
    @user = current_user
  end
end
