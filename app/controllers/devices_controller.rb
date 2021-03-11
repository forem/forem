class DevicesController < ApplicationController
  # Devices can only be created for authenticated users.
  # This replaces the Authenticated Users Pusher Beams solution.
  # See: https://github.com/forem/forem/pull/12419/files#r563906038
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
    device = Device.find_by(device_params)
    unless device
      render json: { error: "Not Found", status: 404 }, status: :not_found
      return
    end

    device&.destroy
    if device&.destroyed?
      head :no_content
    else
      render json: { error: device.errors_as_sentence }, status: :bad_request
    end
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
