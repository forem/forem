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
    valid_private_dm_channel || valid_private_group_channel
  end

  def valid_private_dm_channel
    current_user && params[:channel_name] == ChatChannel.pm_notifications_channel(current_user.id)
  end

  def valid_private_group_channel
    return false unless params[:channel_name].include?("private-channel-")

    id = params[:channel_name].split("-").last
    channel = ChatChannel.find(id)
    channel.has_member?(current_user)
  end
end
