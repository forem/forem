class TwitchStreamUpdatesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    if params["hub.mode"] == "denied"
      # Throw error to error tracker?
      head :no_content
    else
      # Subscription worked!
      render plain: params["hub.challenge"]
    end
  end

  def create
    head :no_content

    unless secret_verified?
      Rails.logger.warn("Twitch Webhook Recieved for which the webhook could not be verified")
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

  def secret_verified?
    twitch_sha = request.headers["x-hub-signature"]
    digest = Digest::SHA256.new
    digest << ApplicationConfig["TWITCH_WEBHOOK_SECRET"]
    digest << request.raw_post

    twitch_sha == "sha256=#{digest.hexdigest}"
  end
end
