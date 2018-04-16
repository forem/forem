json.messages @chat_channel.messages.order("created_at DESC").limit(50).reverse do |message|
  json.user_id message.user.id
  json.username message.user.username
  json.message message.message_markdown
  json.timestamp message.timestamp
  json.color message.user.bg_color_hex
end
