class VideoChatsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def show
    @chat_channel = ChatChannel.find(params[:id]) || not_found
    authorize @chat_channel

    account_sid = ApplicationConfig["TWILIO_ACCOUNT_SID"]
    api_key = ApplicationConfig["TWILIO_VIDEO_API_KEY"]
    api_secret = ApplicationConfig["TWILIO_VIDEO_API_SECRET"]
    @username = display_username
    @video_type = video_type
    token = Twilio::JWT::AccessToken.new(
      account_sid,
      api_key,
      api_secret,
      [],
      identity: @username,
    )

    grant = Twilio::JWT::AccessToken::VideoGrant.new
    grant.room = params[:id]
    token.add_grant(grant)

    @token = token.to_jwt
  end

  private

  def display_username
    return "@#{params[:username]}" if params[:username] && Rails.env.development? # simpler solo testing in dev

    "@#{current_user.username}"
  end

  def video_type
    if @chat_channel.channel_type == "direct" || @chat_channel.chat_channel_memberships.size < 5
      "peer-to-peer"
    else
      "group"
    end
  end
end
