class TwilioTokensController < ApplicationController

  def show
    video_channel = params[:id]
    if (video_channel.start_with?("private-video-channel-") &&
      ChatChannel.find(video_channel.split("private-video-channel-")[1].to_i)).has_member?(current_user)
      @twilio_token = TwilioToken.new(current_user, params[:id]).get
      render json: { status: "success", token: @twilio_token }, status: 200
    else
      render json: { status: "failure", message: "User does not have permission" }, status: 401
    end
  end

end