json.array!(@chat_channels_memberships.sort_by { |m| m.chat_channel.last_message_at }.reverse!) do |membership|
  json.id membership.chat_channel.id
  membership.chat_channel.current_user = current_user
  json.slug membership.chat_channel.slug
  json.channel_name membership.chat_channel.channel_name
  json.channel_type membership.chat_channel.channel_type
  json.last_opened_at membership.chat_channel.last_opened_at
  json.last_message_at membership.chat_channel.last_message_at
  json.adjusted_slug membership.chat_channel.adjusted_slug(current_user)
  json.membership_id membership.id
  json.description membership.chat_channel.description
end
