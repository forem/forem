class ChatChannelMembershipsController < ApplicationController
  after_action :verify_authorized

  def create
    @chat_channel = ChatChannel.find(permitted_params[:chat_channel_id])
    authorize @chat_channel, :update?
    ChatChannelMembership.create(
      user_id: permitted_params[:user_id],
      chat_channel_id: @chat_channel.id,
      status: "pending",
    )
    @chat_channel.index!
  end

  def update
    @chat_channel_membership = ChatChannelMembership.find(session[:id])
    authorize @chat_channel_membership
    if permitted_params[:user_action] == "accept"
      @chat_channel_membership.update(status: "active")
    else
      @chat_channel_membership.update(status: "rejected")
    end
    @chat_channel_membership.chat_channel.index!
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
    @chat_channel_membership.chat_channel.index!
    @chat_channels_memberships = []
    render json: { result: "left channel" }, status: 201
  end

  def permitted_params
    params.require(:chat_channel_membership).permit(:user_id, :chat_channel_id, :user_action, :id)
  end
end
