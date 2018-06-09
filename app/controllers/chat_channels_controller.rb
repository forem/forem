class ChatChannelsController < ApplicationController
  before_action :authenticate_user!, only: [:moderate]

  def index
    if params[:state] == "unopened"
      render_unopened_json_response
    else
      render_channels_html
    end
  end

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

  def open
    @chat_channel = ChatChannel.find(params[:id])
    unless @chat_channel.has_member?(current_user)
      render json: { status: "success", channel: params[:id] }, status: 200
      return
    end
    membership = @chat_channel.chat_channel_memberships.where(user_id: current_user.id).first
    membership.update(last_opened_at: 1.seconds.from_now, has_unopened_messages: false)
    render json: { status: "success", channel: params[:id] }, status: 200
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
        Pusher.trigger(@chat_channel.pusher_channels, "user-banned", { userId: banned_user.id }.to_json)
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

  def render_unopened_json_response
    if current_user.has_role?(:super_admin) || Rails.env.development?
      @chat_channels_memberships = current_user.
      chat_channel_memberships.
      where(has_unopened_messages: true).order("updated_at DESC")
    else
      @chat_channels_memberships = []
    end
    render "index.json"
  end

  def render_channels_html
      @chat_channels = current_user.chat_channels.
        order("last_message_at DESC").
        includes(:chat_channel_memberships)
      @chat_channels.each do |channel|
        channel.current_user = current_user
      end
      slug =  if params[:slug] && params[:slug].start_with?("@")
                        [current_user.username, params[:slug].gsub("@", "")].sort.join("/")
                      else
                        params[:slug]
                      end
      @active_channel = ChatChannel.find_by_slug(slug) || @chat_channels.first
  end
end
