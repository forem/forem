json.array! @chat_channels_memberships do |membership|
  json.adjusted_slug membership.chat_channel.adjusted_slug(current_user)
end
