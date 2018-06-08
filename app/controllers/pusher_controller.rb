class PusherController < ApplicationController

  def auth
    if current_user && params[:channel_name] == "private-message-notifications-#{current_user.id}"
      response = Pusher.authenticate(params[:channel_name], params[:socket_id], {
        user_id: current_user.id, # => required
      })
      render json: response
    else
      render text: 'Forbidden', status: '403'
    end
  end
end