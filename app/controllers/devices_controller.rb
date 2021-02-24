class DevicesController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  rescue_from ActiveRecord::ActiveRecordError do |exc|
    render json: { error: exc.message, status: 422 }, status: :unprocessable_entity
  end

  def create
    device = Device.find_or_create_by(device_params)
    if device.persisted?
      head :ok
    else
      render json: { error: device.errors_as_sentence }, status: :bad_request
    end
  end

  def destroy
    device = Device.where(user_id: params[:id],
                          token: params[:token],
                          platform: params[:platform],
                          app_bundle: params[:app_bundle]).first
    device&.destroy
    render json: { error: device.errors_as_sentence }, status: :bad_request
  end

  private

  def device_params
    {
      user: current_user,
      token: params[:token],
      platform: params[:platform],
      app_bundle: params[:app_bundle]
    }
  end
end
