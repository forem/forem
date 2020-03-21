class ChatChannelMembershipsController < ApplicationController
  after_action :verify_authorized

  def index
    skip_authorization
    @pending_invites = current_user.chat_channel_memberships.includes(:chat_channel).where(status: "pending")
  end

  def find_by_chat_channel_id
    @membership = ChatChannelMembership.where(chat_channel_id: params[:chat_channel_id], user_id: current_user.id).first!
    authorize @membership
    render json: @membership.to_json(
      only: %i[id status viewable_by chat_channel_id last_opened_at],
      methods: %i[channel_text channel_last_message_at channel_status channel_username
                  channel_type channel_text channel_name channel_image channel_modified_slug channel_messages_count],
    )
  end

  def edit
    @membership = ChatChannelMembership.find(params[:id])
    @channel = @membership.chat_channel
    authorize @membership
  end

  def create
    membership_params = params[:chat_channel_membership]
    @chat_channel = ChatChannel.find(membership_params[:chat_channel_id])
    authorize @chat_channel, :update?
    usernames = membership_params[:invitation_usernames].split(",")
    number_invitations_sent = 0
    usernames.each do |username_str|
      user_id = User.find_by(username: username_str.delete(" ").delete("@"))&.id
      next unless user_id

      number_invitations_sent += 1
      ChatChannelMembership.find_or_create_by(user_id: user_id, chat_channel_id: @chat_channel.id)
                           .update(status: "pending")
    end
    flash[:settings_notice] = if number_invitations_sent.zero?
                                "No Invitations Sent. Check for username typos."
                              elsif number_invitations_sent == 1
                                "Invitation Sent."
                              else
                                "#{number_invitations_sent} Invitations Sent."
                              end
    redirect_to edit_chat_channel_membership_path(@chat_channel.chat_channel_memberships.where(user_id: current_user).first&.id)
  end

  def remove_membership
    @chat_channel = ChatChannel.find(params[:chat_channel_id])
    authorize @chat_channel, :update?
    @chat_channel_membership = @chat_channel.chat_channel_memberships.find(params[:membership_id])
    if params[:status] == "pending"
      @chat_channel_membership.destroy
      flash[:settings_notice] = "Invitation Removed."
    else
      @chat_channel_membership.update(status: "removed_from_channel")
      flash[:settings_notice] = "Removed #{@chat_channel_membership.user.name}"
    end
    redirect_to edit_chat_channel_membership_path(ChatChannelMembership.where(chat_channel_id: params[:chat_channel_id], user_id: current_user).first&.id)
  end

  def update
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    if permitted_params[:user_action].present?
      respond_to_invitation
    else
      @chat_channel_membership.update(permitted_params)
      flash[:settings_notice] = "Personal Settings Updated."
      redirect_to edit_chat_channel_membership_path(@chat_channel_membership.id)
    end
  end

  def destroy
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    @channel_name = @chat_channel_membership.chat_channel.channel_name
    @chat_channel_membership.update(status: "left_channel")
    @chat_channels_memberships = []
    flash[:settings_notice] = "You have left the channel #{@channel_name}. It may take a moment to be removed from your list."
    redirect_to chat_channel_memberships_path
  end

  def permitted_params
    params.require(:chat_channel_membership).permit(:user_action, :show_global_badge_notification)
  end

  private

  def respond_to_invitation
    if permitted_params[:user_action] == "accept"
      @chat_channel_membership.update(status: "active")
      @channel_name = @chat_channel_membership.chat_channel.channel_name
      @chat_channel_membership.index!
      flash[:settings_notice] = "Invitation to  #{@channel_name} Accepted. It may take a moment to show up in your list."
    else
      @chat_channel_membership.update(status: "rejected")
      flash[:settings_notice] = "Invitation Rejected."
    end
    redirect_to chat_channel_memberships_path
  end
end
