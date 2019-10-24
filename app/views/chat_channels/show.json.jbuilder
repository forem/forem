json.messages @chat_messages.reverse do |message|
  json.user_id message.user_id
  json.username message.user.username
  json.profile_image_url ProfileImage.new(message.user).get(90)
  json.message message.message_html
  json.timestamp message.created_at
  json.color message.preferred_user_color
end

json.key_format! camelize: :lower

json.chat_channel_id @chat_channel.id
