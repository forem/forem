class ChatChannelMembershipsController < ApplicationController
  def create
    @chat_channel = ChatChannel.find(params[:chat_channel_id])
    authorize @chat_channel, :update?
    ChatChannelMembership.create(
      user_id: params[:user_id],
      chat_channel_id: @chat_channel.id,
      status: "pending"
    )
  end

  def update
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    if params[:user_action] == "accept"
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
end