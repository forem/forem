module MessagesHelper
  def create_pusher_payload(new_message, temp_id)
    payload = {
      temp_id: temp_id,
      id: new_message.id,
      user_id: new_message.user.id,
      chat_channel_id: new_message.chat_channel.id,
      chat_channel_adjusted_slug: new_message.chat_channel.adjusted_slug(current_user, "sender"),
      channel_type: new_message.chat_channel.channel_type,
      username: new_message.user.username,
      profile_image_url: Images::Profile.call(new_message.user.profile_image_url, length: 90),
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

  def pusher_message_created(is_single, message, temp_message_id)
    return unless message.valid?

    begin
      message_json = create_pusher_payload(message, temp_message_id)
      if is_single
        Pusher.trigger(ChatChannel.pm_notifications_channel(message.user_id), "message-created", message_json)
      else
        Pusher.trigger(message.chat_channel.pusher_channels, "message-created", message_json)
      end
    rescue Pusher::Error => e
      Honeybadger.notify(e)
    end
  end
end
