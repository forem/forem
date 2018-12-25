class ApiSecretsController < ApplicationController
  before_action :set_api_secret, only: :destroy
  after_action :verify_authorized

  def create
    authorize ApiSecret
    @secret = ApiSecret.new(permitted_attributes(ApiSecret))
    @secret.user_id = current_user.id
    if @secret.save
      flash[:notice] = "Your access token has been generated: #{@secret.secret}. Be sure to copy it to somewhere safe now. You won’t be able to see it again!"
      redirect_back(fallback_location: root_path)
    end
  end

  def destroy
    authorize @secret
    if @secret.destroy
      flash[:notice] = "Your access token has been revoked."
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def set_api_secret
    @secret = ApiSecret.find_by_id(params[:id]) || not_found
  end
end
