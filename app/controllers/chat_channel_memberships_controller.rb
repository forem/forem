class ChatChannelMembershipsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized, except: %w[join_channel request_details]

  include MessagesHelper
  include ChatChannelMembershipsHelper

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    skip_authorization
    memberships = current_user.chat_channel_memberships.includes(:chat_channel)
    @pending_invites = memberships.filter_by_status("pending")
  end

  def find_by_chat_channel_id
    @membership = ChatChannelMembership.where(chat_channel_id: params[:chat_channel_id],
                                              user_id: current_user.id).first!
    authorize @membership
    render json: @membership.to_json(
      only: %i[id status viewable_by chat_channel_id last_opened_at],
      methods: %i[channel_text channel_last_message_at channel_status channel_username
                  channel_type channel_text channel_name channel_image channel_modified_slug channel_messages_count],
    )
  end

  def chat_channel_info
    @membership = ChatChannelMembership.find(params[:id])
    authorize @membership
    @channel = @membership.chat_channel
    invite_cache_key = "chat-channel-invite-#{@channel.id}"
    invitation_slug = Rails.cache.fetch(invite_cache_key, expires_in: 80.hours) do
      "invitation-link-#{SecureRandom.hex(3)}"
    end
    @invitation_link = "/join_channel_invitation/#{@channel.slug}?invitation_slug=#{invitation_slug}"
  end

  def create_membership_request
    chat_channel = ChatChannel.find_by(id: channel_membership_params[:chat_channel_id])
    authorize chat_channel, :update?
    message = ChatChannels::SendInvitation.call(
      channel_membership_params[:invitation_usernames],
      current_user,
      chat_channel,
    )

    render json: { success: true, message: message, data: {} }, status: :ok
  end

  def join_channel
    membership_params = params[:chat_channel_membership]
    chat_channel = ChatChannel.find(membership_params[:chat_channel_id])
    existing_membership = ChatChannelMembership.find_by(user_id: current_user.id, chat_channel_id: chat_channel.id)
    if existing_membership.present? && %w[active joining_request].exclude?(existing_membership.status)
      status = existing_membership.update(status: "joining_request", role: "member")
    else
      membership = ChatChannelMembership.new(user_id: current_user.id, chat_channel_id: chat_channel.id,
                                             role: "member", status: "joining_request")
      status = membership.save
    end
    if status
      render json: { status: "success", message: "Request Sent" }, status: :ok
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
      message = "Invitation removed."
    else
      membership = @chat_channel_membership
      message = "@#{current_user.username} removed @#{membership.user.username} from #{membership.channel_name}"
      send_chat_action_message(
        message, current_user, @chat_channel_membership.chat_channel_id, "removed_from_channel"
      )
      @chat_channel_membership.update(status: "removed_from_channel")
      message = "Removed #{@chat_channel_membership.user.name}"
    end

    render json: { status: "success", message: message, success: true }, status: :ok
  end

  def add_membership
    @chat_channel = ChatChannel.find(params[:chat_channel_id])
    authorize @chat_channel, :update?
    @chat_channel_membership = @chat_channel.chat_channel_memberships.find(params[:membership_id])

    return unless permitted_params[:user_action].present? && @chat_channel_membership.status == "joining_request"

    respond_to_invitation(@chat_channel_membership.status)
  end

  def update
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    respond_to_invitation(@chat_channel_membership.status)
  end

  def update_membership
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    @chat_channel_membership.update(permitted_params)
    if @chat_channel_membership.errors.any?
      render json: { success: false, errors: @chat_channel_membership.errors.full_messages,
                     message: "Failed to update settings." }, status: :bad_request
    else
      render json: { success: true, message: "Personal settings updated." }, status: :ok
    end
  end

  def leave_membership
    chat_channel_membership = ChatChannelMembership.find_by(id: params[:id])
    authorize chat_channel_membership
    channel_name = chat_channel_membership.chat_channel.channel_name
    send_chat_action_message("@#{current_user.username} left #{chat_channel_membership.channel_name}", current_user,
                             chat_channel_membership.chat_channel_id, "left_channel")
    chat_channel_membership.update(status: "left_channel")
    message = "You have left the channel #{channel_name}. It may take a moment to be removed from your list."
    if chat_channel_membership.errors.any?
      render json: { success: false, message: "Failed to update membership",
                     errors: chat_channel_membership.errors.full_messages }, status: :bad_request
    else
      render json: { success: true, message: message },  status: :ok
    end
  end

  def request_details
    user_chat_channels = ChatChannel.includes(:chat_channel_memberships).where(
      chat_channel_memberships: { user_id: current_user.id, role: "mod", status: "active" },
    )
    @memberships = user_chat_channels.flat_map(&:requested_memberships)
    @user_invitations = ChatChannelMembership.where(
      user_id: current_user.id,
      status: %w[pending],
    ).order("created_at DESC")
  end

  def update_membership_role
    @chat_channel = ChatChannel.find_by(id: params[:id])
    authorize @chat_channel, :update?
    membership = ChatChannelMembership.find_by(
      id: channel_membership_params[:membership_id],
      chat_channel_id: @chat_channel.id,
    )

    membership.update(role: channel_membership_params[:role])
    if membership.errors.any?
      render json: {
        success: false,
        message: "Failed to update membership",
        errors: chat_channel_membership.errors.full_messages
      }, status: :bad_request
    else
      role = membership.reload.role
      send_chat_action_message(
        "@#{membership.user.username} role is updated as #{role}",
        current_user, @chat_channel.id,
        "updated"
      )

      render json: { success: true, message: "User Membership is updated" }, status: :ok
    end
  end

  def join_channel_invitation
    @chat_channel = ChatChannel.find_by(slug: params[:channel_slug])
    authorize @chat_channel
    invite_cache_key = "chat-channel-invite-#{@chat_channel.id}"
    invitation_slug = Rails.cache.read(invite_cache_key)
    existing_membership = ChatChannelMembership.find_by(user_id: current_user.id, chat_channel_id: @chat_channel.id)
    redirect_to "/connect/#{@chat_channel.slug}" if existing_membership && existing_membership.status == "active"
    @link_expired = true if invitation_slug != params[:invitation_slug]
  end

  def joining_invitation_response
    chat_channel = ChatChannel.find_by(id: params[:chat_channel_id])
    authorize chat_channel
    if params[:user_action] == "accept"
      membership = ChatChannelMembership.find_by(user_id: current_user.id, chat_channel_id: chat_channel.id)
      if !membership
        membership = ChatChannelMembership.create(user_id: current_user.id, chat_channel_id: chat_channel.id)
        unless membership&.errors&.any?
          send_chat_action_message("@#{membership.user.username} join the channel", current_user, chat_channel.id,
                                   "joined")
        end
      elsif membership.status != "active"
        # This check checks if the user already has the chatChannelMembership with the status pending, joining_request
        # Then update it to as active.
        membership.update(role: "member", status: "active")
        send_chat_action_message("@#{membership.user.username} join the channel", current_user,
                                 membership.chat_channel_id, "joined")
      end

      if membership&.errors&.any?
        flash[:settings_notice] = membership.errors.full_messages
        redirect_to root_path
      end

      redirect_to connect_path(chat_channel.slug)
    else
      redirect_to root_path
    end
  end

  private

  def permitted_params
    params.require(:chat_channel_membership).permit(:user_action, :show_global_badge_notification)
  end

  def channel_membership_params
    params.require(:chat_channel_membership).permit(:chat_channel_id, :invitation_usernames, :membership_id, :role)
  end

  def respond_to_invitation(previous_status)
    if permitted_params[:user_action] == "accept"
      @chat_channel_membership.update(status: "active")
      channel_name = @chat_channel_membership.chat_channel.channel_name

      if previous_status == "pending"
        send_chat_action_message(
          "@#{current_user.username} joined #{@chat_channel_membership.channel_name}",
          current_user,
          @chat_channel_membership.chat_channel_id,
          "joined",
        )

        notice = "Invitation to #{channel_name} accepted. It may take a moment to show up in your list."
      else
        send_chat_action_message(
          "@#{current_user.username} added @#{@chat_channel_membership.user.username}",
          current_user,
          @chat_channel_membership.chat_channel_id,
          "joined",
        )

        NotifyMailer
          .with(membership: @chat_channel_membership, inviter: @chat_channel_membership.user)
          .channel_invite_email
          .deliver_later

        notice = "Accepted request of #{@chat_channel_membership.user.username} to join #{channel_name}."
      end
    else
      @chat_channel_membership.update(status: "rejected")
      notice = "Invitation rejected."
    end

    membership_user = format_membership(@chat_channel_membership)
    flash[:settings_notice] = notice

    respond_to do |format|
      format.html { redirect_to chat_channel_memberships_path }
      format.json do
        render json: {
          status: "success",
          message: flash[:settings_notice],
          success: true,
          membership: membership_user
        }, status: :ok
      end
    end
  end

  def send_chat_action_message(message, user, channel_id, action)
    temp_message_id = SecureRandom.hex(20)
    message = Message.create("message_markdown" => message, "user_id" => user.id, "chat_channel_id" => channel_id,
                             "chat_action" => action)
    pusher_message_created(false, message, temp_message_id) unless message.left_channel?
  end

  def user_not_authorized
    render json: { success: false, message: "User not authorized" }, status: :unauthorized
  end

  def record_not_found
    render json: { success: false, message: "not found" }, status: :not_found
  end
end
