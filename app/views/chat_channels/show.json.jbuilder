json.messages @chat_channel.messages do |message|
  json.username message.user.username
  json.message message.message_markdown
  json.timestamp message.timestamp
  json.color message.user.bg_color_hex
end
