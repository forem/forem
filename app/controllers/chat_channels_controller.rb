class ChatChannelsController < ApplicationController
  def show
    @chat_channel = ChatChannel.includes(:messages).find_by(id: params[:id])
    if @chat_channel
      @chat_channel
    else
      render json: ["The chat channel you are looking for is either invalid or does not exist"],
             status: 401
    end
  end
end
