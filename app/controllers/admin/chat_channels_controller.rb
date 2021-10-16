module Admin
  class ChatChannelsController < Admin::ApplicationController
    layout "admin"

    CHAT_ALLOWED_PARAMS = %i[usernames_string channel_name username_string].freeze

    def index
      @q = ChatChannel.where(channel_type: "invite_only").includes(:users).ransack(params[:q])
      @group_chat_channels = @q.result.page(params[:page]).per(50)
    end

    def create
      ChatChannels::CreateWithUsers.call(
        users: users_by_param,
        channel_type: "invite_only",
        contrived_name: chat_channel_params[:channel_name],
        membership_role: "mod",
      )
      redirect_back(fallback_location: admin_chat_channels_path)
    end

    def update
      @chat_channel = ChatChannel.find(params[:id])
      @chat_channel.invite_users(users: users_by_param)
      redirect_back(fallback_location: admin_chat_channels_path)
    end

    def remove_user
      @chat_channel = ChatChannel.find(params[:id])
      @chat_channel.remove_user(user_by_param)
      redirect_back(fallback_location: admin_chat_channels_path)
    end

    def destroy
      @chat_channel = ChatChannel.find(params[:id])
      if @chat_channel.users.count.zero?
        @chat_channel.destroy
        flash[:success] = "Channel was successfully deleted."
      else
        flash[:alert] = "Channel NOT deleted, because it still has users."
      end
      redirect_back(fallback_location: admin_chat_channels_path)
    end

    private

    def users_by_param
      User.where(username: chat_channel_params[:usernames_string].downcase.delete(" ").split(","))
    end

    def user_by_param
      User.find_by(username: chat_channel_params[:username_string])
    end

    def chat_channel_params
      params.require(:chat_channel).permit(CHAT_ALLOWED_PARAMS)
    end
  end
end
