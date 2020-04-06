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

  def update
    @chat_channel_membership = ChatChannelMembership.find(params[:id])
    authorize @chat_channel_membership
    if permitted_params[:user_action].present?
      respond_to_invitation
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

  def respond_to_invitation
    if permitted_params[:user_action] == "accept"
      @chat_channel_membership.update(status: "active")
      channel_name = @chat_channel_membership.chat_channel.channel_name
      send_chat_action_message("@#{current_user.username} joined #{@chat_channel_membership.channel_name}", current_user, @chat_channel_membership.chat_channel_id, "joined")
      flash[:settings_notice] = "Invitation to  #{channel_name} accepted. It may take a moment to show up in your list."
    else
      @chat_channel_membership.update(status: "rejected")
      flash[:settings_notice] = "Invitation rejected."
    end
    redirect_to chat_channel_memberships_path
  end

  def send_chat_action_message(message, user, channel_id, action)
    @temp_message_id = (0...20).map { ("a".."z").to_a[rand(8)] }.join
    @message = Message.create("message_markdown" => message, "user_id" => user.id, "chat_channel_id" => channel_id, "chat_action" => action)
    pusher_message_created(false)
  end

  def pusher_message_created(is_single)
    return unless @message.valid?

    begin
      message_json = create_pusher_payload(@message, @temp_message_id)
      if is_single
        Pusher.trigger("private-message-notifications-#{@message.user_id}", "message-created", message_json)
      else
        Pusher.trigger(@message.chat_channel.pusher_channels, "message-created", message_json)
      end
    rescue Pusher::Error => e
      logger.info "PUSHER ERROR: #{e.message}"
    end
  end

  def create_pusher_payload(new_message, temp_id)
    payload = {
      temp_id: temp_id,
      id: new_message.id,
      user_id: new_message.user.id,
      chat_channel_id: new_message.chat_channel.id,
      chat_channel_adjusted_slug: new_message.chat_channel.adjusted_slug(current_user, "sender"),
      channel_type: new_message.chat_channel.channel_type,
      username: new_message.user.username,
      profile_image_url: ProfileImage.new(new_message.user).get(width: 90),
      message: new_message.message_html,
      markdown: new_message.message_markdown,
      edited_at: new_message.edited_at,
      timestamp: Time.current,
      color: new_message.preferred_user_color,
      reception_method: "pushed",
      action: new_message.chat_action
    }

    if new_message.chat_channel.group?
      payload[:chat_channel_adjusted_slug] = new_message.chat_channel.adjusted_slug
    end
    payload.to_json
  end
end
