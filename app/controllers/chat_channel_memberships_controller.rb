class ChatChannelMembershipsController < ApplicationController
  after_action :verify_authorized

  def find_by_chat_channel_id
    @membership = ChatChannelMembership.where(chat_channel_id: params[:chat_channel_id], user_id: current_user.id).first!
    authorize @membership
    render json: @membership.to_json(
      only: %i[id status viewable_by chat_channel_id last_opened_at],
      methods: %i[channel_text channel_last_message_at channel_status channel_username
                  channel_type channel_text channel_name channel_image channel_modified_slug channel_messages_count],
    )
  end

  def create
    @chat_channel = ChatChannel.find(permitted_params[:chat_channel_id])
    authorize @chat_channel, :update?
    ChatChannelMembership.create(
      user_id: permitted_params[:user_id],
      chat_channel_id: @chat_channel.id,
      status: "pending",
    )
  end

  def update
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    if permitted_params[:user_action] == "accept"
      @chat_channel_membership.update(status: "active")
    else
      @chat_channel_membership.update(status: "rejected")
    end
    @chat_channels_memberships = current_user.
      chat_channel_memberships.includes(:chat_channel).
      where(status: "pending").
      order("chat_channel_memberships.updated_at DESC")
    render "chat_channels/index.json"
  end

  def destroy
    @chat_channel_membership = ChatChannel.find(params[:id]).
      chat_channel_memberships.where(user_id: current_user.id).first
    authorize @chat_channel_membership
    @chat_channel_membership.update(status: "left_channel")
    @chat_channels_memberships = []
    render json: { result: "left channel" }, status: :created
  end

  def permitted_params
    params.require(:chat_channel_membership).permit(:user_id, :chat_channel_id, :user_action, :id)
  end
end
