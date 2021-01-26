json.messages @chat_messages.reverse do |message|
  json.extract!(message, :id, :user_id, :edited_at)

  json.username message.user.username
  json.profile_image_url Images::Profile.call(message.user.profile_image_url, length: 90)
  json.message message.message_html
  json.markdown message.message_markdown
  json.timestamp message.created_at
  json.color message.preferred_user_color
  json.action message.chat_action
end

json.key_format! camelize: :lower

json.chat_channel_id @chat_channel.id
