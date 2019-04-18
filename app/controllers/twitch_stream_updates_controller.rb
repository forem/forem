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
    Rails.logger.debug params

    head :no_content
  end
end
