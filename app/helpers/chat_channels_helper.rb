module ChatChannelsHelper
  def unopened_json_response
    if session_current_user_id
      ChatChannelMembership.where(user_id: session_current_user_id)
        .where(has_unopened_messages: true)
        .where(show_global_badge_notification: true)
        .where.not(status: %w[removed_from_channel left_channel])
        .includes(%i[chat_channel user])
        .order("chat_channel_memberships.updated_at" => :desc)
    else
      ChatChannelMembership.none
    end
  end

  def pending_json_response
    if current_user
      current_user
        .chat_channel_memberships.includes(:chat_channel)
        .where(status: "pending")
        .order("chat_channel_memberships.updated_at" => :desc)
    else
      ChatChannelMembership.none
    end
  end

  def unopened_ids_response
    ChatChannelMembership.where(user_id: session_current_user_id).includes(:chat_channel)
      .where(has_unopened_messages: true).where.not(status: %w[removed_from_channel
                                                               left_channel]).pluck(:chat_channel_id)
  end

  def joining_request_json_response
    requested_memberships_id = current_user
      .chat_channel_memberships
      .includes(:chat_channel)
      .where(chat_channels: { discoverable: true }, role: "mod")
      .pluck(:chat_channel_id)
      .flat_map { |membership_id| ChatChannel.find_by(id: membership_id).requested_memberships.ids }

    ChatChannelMembership
      .includes(%i[user chat_channel])
      .where(id: requested_memberships_id)
  end
end
