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
    user = User.find(params[:user_id])

    if params[:data].first.present?
      user.update!(currently_streaming_on: :twitch)
    else
      user.update!(currently_streaming_on: nil)
    end

    head :no_content
  end
end
