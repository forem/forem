class ChatChannelsController < ApplicationController
  before_action :authenticate_user!, only: [:moderate]
  after_action :verify_authorized

  def index
    if params[:state] == "unopened"
      authorize ChatChannel
      render_unopened_json_response
    elsif params[:state] == "pending"
      authorize ChatChannel
      render_pending_json_response
    else
      skip_authorization
      render_channels_html
    end
  end

  def show
    @chat_channel = ChatChannel.find_by_id(params[:id]) || not_found
    authorize @chat_channel
  end

  def create
    authorize ChatChannel
    @chat_channel = ChatChannelCreationService.new(current_user, params[:chat_channel]).create
    if @chat_channel.valid?
      render json: { status: "success", chat_channel: @chat_channel.to_json(only: [:channel_name,:slug]) }, status: 200
    else
      render json: { errors: @chat_channel.errors.full_messages }
    end
  end

  def update
    @chat_channel = ChatChannel.find(params[:id])
    authorize @chat_channel
    ChatChannelUpdateService.new(@chat_channel, chat_channel_params).update
    if @chat_channel.valid?
      render json: { status: "success", chat_channel: @chat_channel.to_json(only: [:channel_name,:slug]) }, status: 200
    else
      render json: { errors: @chat_channel.errors.full_messages }
    end
  end

  def open
    @chat_channel = ChatChannel.find(params[:id])
    authorize @chat_channel
    membership = @chat_channel.chat_channel_memberships.where(user_id: current_user.id).first
    membership.update(last_opened_at: 1.seconds.from_now, has_unopened_messages: false)
    @chat_channel.index!
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
    params.require(:chat_channel).permit(policy(ChatChannel).permitted_attributes)
  end

  def render_unopened_json_response
    if current_user
      @chat_channels_memberships = current_user.
      chat_channel_memberships.includes(:chat_channel).
      where("has_unopened_messages = ? OR status = ?", true, "pending").
      order("chat_channel_memberships.updated_at DESC")
    else
      @chat_channels_memberships = []
    end
    render "index.json"
  end

  def render_pending_json_response
    if current_user
      @chat_channels_memberships = current_user.
      chat_channel_memberships.includes(:chat_channel).
      where(status: "pending").
      order("chat_channel_memberships.updated_at DESC")
    else
      @chat_channels_memberships = []
    end
    render "index.json"
  end


  def render_channels_html
    return unless current_user
    if params[:slug]
      slug =  if params[:slug] && params[:slug].start_with?("@")
                        [current_user.username, params[:slug].gsub("@", "")].sort.join("/")
                      else
                        params[:slug]
                      end
      @active_channel = ChatChannel.find_by_slug(slug)
      @active_channel.current_user = current_user if @active_channel
    end
    generate_github_token
    generate_algolia_search_key
  end

  def generate_algolia_search_key
    current_user_id = current_user.id
    params = {filters: "viewable_by:#{current_user_id} AND status: active"}
    @secured_algolia_key = Algolia.generate_secured_api_key(
      ENV["ALGOLIASEARCH_SEARCH_ONLY_KEY"], params,
    )
  end

  def generate_github_token
    @github_token = Identity.where(user_id: current_user.id, provider: "github").first&.token
  end
end
