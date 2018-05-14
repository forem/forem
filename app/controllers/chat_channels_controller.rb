class ChatChannelsController < ApplicationController
  before_action :authenticate_user!, only: [:moderate]

  def show
    @chat_channel = ChatChannel.includes(:messages).find_by(id: params[:id])
    if @chat_channel
      @chat_channel
    else
      message = "The chat channel you are looking for is either invalid or does not exist"
      render json: { error: message },
             status: 401
    end
  end

  def moderate
    @chat_channel = ChatChannel.find(params[:id])
    authorize @chat_channel
    command = chat_channel_params[:command].split
    case command[0]
    when "/ban"
      banned_user = User.find_by_username(command[1])
      if banned_user
        banned_user.add_role :banned
        banned_user.messages.each(&:destroy!)
        Pusher.trigger(@chat_channel.id, "user-banned", { userId: banned_user.id }.to_json)
        render json: { status: "success", message: "banned!" }, status: 200
      else
        render json: { status: "error", message: "username not found" }, status: 400
      end
    when "/unban"
      banned_user = User.find_by_username(command[1])
      if banned_user
        banned_user.remove_role :banned
        render json: { status: "success", message: "unbanned!" }, status: 200
      else
        render json: { status: "error", message: "username not found" }, status: 400
      end
    when "/clearchannel"
      @chat_channel.clear_channel
      render json: { status: "success", message: "cleared!" }, status: 200
    else
      render json: { status: "error", message: "invalid command" }, status: 400
    end
  end

  private

  def chat_channel_params
    params.require(:chat_channel).permit(:command)
  end
end
