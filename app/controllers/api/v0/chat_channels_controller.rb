module Api
  module V0
    class ChatChannelsController < ApplicationController
      def show
        @chat_channel = ChatChannel.find(params[:id])
        raise unless @chat_channel.has_member?(current_user)
      end
    end
  end
end
