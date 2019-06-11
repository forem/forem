class ApiSecretsController < ApplicationController
  before_action :load_api_secret, only: :destroy
  after_action :verify_authorized

  def create
    authorize ApiSecret

    @secret = ApiSecret.new(permitted_attributes(ApiSecret))
    @secret.user_id = current_user.id

    if @secret.save
      flash[:notice] = "Your access token has been generated: #{@secret.secret}"
    else
      flash[:error] = @secret.errors.full_messages.to_sentence
    end

    redirect_back(fallback_location: root_path)
  end

  def destroy
    authorize @secret

    if @secret.destroy
      flash[:notice] = "Your access token has been revoked."
    else
      flash[:error] = "An error occurred. Please try again or send an email to: yo@dev.to"
    end

    redirect_back(fallback_location: root_path)
  end

  private

  def load_api_secret
    @secret = ApiSecret.find(destroy_params[:id])
  end

  def destroy_params
    params.permit(:id)
  end
end
