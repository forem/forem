module Api
  module V0
    class ChatChannelsController < ApiController
      def show
        @chat_channel = ChatChannel.find(params[:id])
        error_not_found unless @chat_channel.has_member?(current_user)
      end
    end
  end
end
