json.type_of "chat_channel"

json.extract!(
  @chat_channel,
  :id,
  :description,
  :channel_name,
  :channel_users,
  :channel_mod_ids,
  :pending_users_select_fields,
)

json.username @chat_channel.channel_name
