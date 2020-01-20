class TwitchLiveStreamsController < ApplicationController
  before_action :set_cache_control_headers

  def show
    @user = User.find_by!(username: params[:username].tr("@", "").downcase)
    set_surrogate_key_header @user.record_key
    if @user.twitch_username.present?
      render :show
    else
      render :no_twitch
    end
  end
end
