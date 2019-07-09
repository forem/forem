module Messages
  class SendPushJob < ApplicationJob
    queue_as :messages_send_push

    def perform(user_id, chat_channel_id, message_html, service = Messages::SendPush)
      user = User.find_by(id: user_id)
      chat_channel = ChatChannel.find_by(id: chat_channel_id)

      return unless user && chat_channel

      service.call(user, chat_channel, message_html)
    end
  end
end
