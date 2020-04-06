class VideoChatsController < ApplicationController
  before_action :authenticate_user!

  def show
    account_sid = ApplicationConfig["TWILIO_ACCOUNT_SID"]
    api_key = ApplicationConfig["TWILIO_VIDEO_API_KEY"]
    api_secret = ApplicationConfig["TWILIO_VIDEO_API_SECRET"]

    token = Twilio::JWT::AccessToken.new(
      account_sid,
      api_key,
      api_secret,
      [],
      identity: current_user.id,
    )

    grant = Twilio::JWT::AccessToken::VideoGrant.new
    grant.room = params[:id]
    token.add_grant(grant)

    @token = token.to_jwt
  end
end
