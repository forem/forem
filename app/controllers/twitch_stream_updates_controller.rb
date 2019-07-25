class TwitchStreamUpdatesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    if params["hub.mode"] == "denied"
      airbrake_logger.error("Twitch Webhook was denied: #{params.permit('hub.mode', 'hub.reason', 'hub.topic').to_json}")
      head :no_content
    else
      render plain: params["hub.challenge"]
    end
  end

  def create
    head :no_content

    unless secret_verified?
      airbrake_logger.warn("Twitch Webhook Received for which the webhook could not be verified")
      return
    end

    user = User.find(params[:user_id])

    if params[:data].first.present?
      user.update!(currently_streaming_on: :twitch)
    else
      user.update!(currently_streaming_on: nil)
    end
  end

  private

  def airbrake_logger
    Airbrake::AirbrakeLogger.new(Rails.logger)
  end

  def secret_verified?
    twitch_sha = request.headers["x-hub-signature"]
    digest = OpenSSL::HMAC.hexdigest("SHA256", ApplicationConfig["TWITCH_WEBHOOK_SECRET"], request.raw_post)

    twitch_sha == "sha256=#{digest}"
  end
end
