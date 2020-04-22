memberships = @chat_channels_memberships.sort_by { |m| m.chat_channel.last_message_at }.reverse!

json.array!(memberships) do |membership|
  membership.chat_channel.current_user = current_user

  json.extract!(
    membership.chat_channel,
    :id,
    :slug,
    :channel_name,
    :channel_type,
    :last_opened_at,
    :last_message_at,
    :description,
  )

  json.adjusted_slug membership.chat_channel.adjusted_slug(current_user)
  json.membership_id membership.id
end
