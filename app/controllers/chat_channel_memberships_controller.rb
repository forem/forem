class ChatChannelMembershipsController < ApplicationController
  after_action :verify_authorized, except: :join_channel
  include MessagesHelper

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
    usernames = membership_params[:invitation_usernames].split(",").map { |username| username.strip.delete("@") }
    users = User.where(username: usernames)
    invitations_sent = @chat_channel.invite_users(users: users, membership_role: "member", inviter: current_user)
    flash[:settings_notice] = if invitations_sent.zero?
                                "No invitations sent. Check for username typos."
                              else
                                "#{invitations_sent} #{'invitation'.pluralize(invitations_sent)} sent."
                              end
    membership = @chat_channel.chat_channel_memberships.find_by!(user: current_user)
    redirect_to edit_chat_channel_membership_path(membership)
  end

  def join_channel
    membership_params = params[:chat_channel_membership]
    chat_channel = ChatChannel.find(membership_params[:chat_channel_id])
    existing_membership = ChatChannelMembership.find_by(user_id: current_user.id, chat_channel_id: chat_channel.id)
    if existing_membership.present? && %w[active joining_request].exclude?(existing_membership.status)
      status = existing_membership.update(status: "joining_request", role: "member")
    else
      membership = ChatChannelMembership.new(user_id: current_user.id, chat_channel_id: chat_channel.id, role: "member", status: "joining_request")
      status = membership.save
    end
    if status
      render json: { status: "success", message: "Request Sent" }
    else
      render json: { status: 400, message: "Unable to join channel" }, status: :bad_request
    end
  end

  def remove_membership
    @chat_channel = ChatChannel.find(params[:chat_channel_id])
    authorize @chat_channel, :update?
    @chat_channel_membership = @chat_channel.chat_channel_memberships.find(params[:membership_id])
    if params[:status] == "pending"
      @chat_channel_membership.destroy
      flash[:settings_notice] = "Invitation removed."
    else
      send_chat_action_message("@#{current_user.username} removed @#{@chat_channel_membership.user.username} from #{@chat_channel_membership.channel_name}", current_user, @chat_channel_membership.chat_channel_id, "removed_from_channel")
      @chat_channel_membership.update(status: "removed_from_channel")
      flash[:settings_notice] = "Removed #{@chat_channel_membership.user.name}"
    end
    membership = ChatChannelMembership.find_by!(chat_channel_id: params[:chat_channel_id], user: current_user)
    redirect_to edit_chat_channel_membership_path(membership)
  end

  def add_membership
    @chat_channel = ChatChannel.find(params[:chat_channel_id])
    authorize @chat_channel, :update?
    @chat_channel_membership = @chat_channel.chat_channel_memberships.find(params[:membership_id])
    respond_to_invitation(@chat_channel_membership.status) if permitted_params[:user_action].present? && @chat_channel_membership.status == "joining_request"
  end

  def update
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    if permitted_params[:user_action].present?
      respond_to_invitation(@chat_channel_membership.status)
    else
      @chat_channel_membership.update(permitted_params)
      flash[:settings_notice] = "Personal settings updated."
      redirect_to edit_chat_channel_membership_path(@chat_channel_membership.id)
    end
  end

  def destroy
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    channel_name = @chat_channel_membership.chat_channel.channel_name
    send_chat_action_message("@#{current_user.username} left #{@chat_channel_membership.channel_name}", current_user, @chat_channel_membership.chat_channel_id, "left_channel")
    @chat_channel_membership.update(status: "left_channel")
    @chat_channels_memberships = []
    flash[:settings_notice] = "You have left the channel #{channel_name}. It may take a moment to be removed from your list."
    redirect_to chat_channel_memberships_path
  end

  private

  def permitted_params
    params.require(:chat_channel_membership).permit(:user_action, :show_global_badge_notification)
  end

  def respond_to_invitation(previous_status)
    if permitted_params[:user_action] == "accept"
      @chat_channel_membership.update(status: "active")
      channel_name = @chat_channel_membership.chat_channel.channel_name
      if previous_status == "pending"
        send_chat_action_message("@#{current_user.username} joined #{@chat_channel_membership.channel_name}", current_user, @chat_channel_membership.chat_channel_id, "joined")
        flash[:settings_notice] = "Invitation to  #{channel_name} accepted. It may take a moment to show up in your list."
      else
        send_chat_action_message("@#{current_user.username} added @#{@chat_channel_membership.user.username}", current_user, @chat_channel_membership.chat_channel_id, "joined")
        NotifyMailer.channel_invite_email(@chat_channel_membership, @chat_channel_membership.user).deliver_later
        flash[:settings_notice] = "Accepted request of #{@chat_channel_membership.user.username} to join  #{channel_name}."
        membership = ChatChannelMembership.find_by!(chat_channel_id: @chat_channel_membership.chat_channel.id, user: current_user)
        redirect_to(edit_chat_channel_membership_path(membership)) && return
      end
    else
      @chat_channel_membership.update(status: "rejected")
      flash[:settings_notice] = "Invitation rejected."
    end
    redirect_to chat_channel_memberships_path
  end

  def send_chat_action_message(message, user, channel_id, action)
    temp_message_id = (0...20).map { ("a".."z").to_a[rand(8)] }.join
    message = Message.create("message_markdown" => message, "user_id" => user.id, "chat_channel_id" => channel_id, "chat_action" => action)
    pusher_message_created(false, message, temp_message_id)
  end
end
