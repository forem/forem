class PusherController < ApplicationController
  def auth
    if valid_channel
      response = Pusher.authenticate(params[:channel_name], params[:socket_id],
                                     user_id: current_user.id) # => required
      render json: response
    else
      render json: { text: "Forbidden", status: "403" }
    end
  end

  def valid_channel
    valid_private_channel || valid_presence_channel
  end

  def valid_private_channel
    current_user && params[:channel_name] == "private-message-notifications-#{current_user.id}"
  end

  def valid_presence_channel
    return false unless params[:channel_name].include?("presence-channel-")

    id = params[:channel_name].split("presence-channel-")[1].split("-")[0]
    channel = ChatChannel.find(id)
    channel.has_member?(current_user)
  end
end
