class TwilioTokensController < ApplicationController
  after_action :verify_authorized

  def show
    video_channel = params[:id].split("private-video-channel-")[1] if params[:id].start_with?("private-video-channel-")
    unless video_channel
      skip_authorization
      render json: { status: "failure", token: @twilio_token }, status: :not_found
      return
    end
    @chat_channel = ChatChannel.find(video_channel.to_i)
    authorize @chat_channel # show pundit method for chat_channel_policy works here, should always check though
    @twilio_token = Twilio::GetJwtToken.call(current_user, params[:id])
    render json: { status: "success", token: @twilio_token }, status: :ok
  end
end
