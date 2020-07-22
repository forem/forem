module Internal
  class ChatChannelsController < Internal::ApplicationController
    layout "internal"

    def index
      @q = ChatChannel.where(channel_type: "invite_only").includes(:users).ransack(params[:q])
      @group_chat_channels = @q.result.page(params[:page]).per(50)
    end

    def create
      ChatChannel.create_with_users(
        users: users_by_param,
        channel_type: "invite_only",
        contrived_name: chat_channel_params[:channel_name],
        membership_role: "mod",
      )
      redirect_back(fallback_location: "/internal/chat_channels")
    end

    def update
      @chat_channel = ChatChannel.find(params[:id])
      @chat_channel.invite_users(users: users_by_param, membership_role: "mod")
      redirect_back(fallback_location: "/internal/chat_channels")
    end

    def remove_user
      @chat_channel = ChatChannel.find(params[:id])
      @chat_channel.remove_user(user_by_param)
      redirect_back(fallback_location: "/internal/chat_channels")
    end

    private

    def users_by_param
      User.where(username: chat_channel_params[:usernames_string].downcase.delete(" ").split(","))
    end

    def user_by_param
      User.find_by(username: chat_channel_params[:username_string])
    end

    def chat_channel_params
      allowed_params = %i[usernames_string channel_name username_string]
      params.require(:chat_channel).permit(allowed_params)
    end
  end
end
