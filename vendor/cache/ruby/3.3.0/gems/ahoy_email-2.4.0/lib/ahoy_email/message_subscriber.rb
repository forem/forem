module AhoyEmail
  class MessageSubscriber
    def track_click(event)
      message = AhoyEmail.message_model.find_by(token: event[:token])
      if message
        message.clicked ||= true if message.respond_to?(:clicked=)
        message.clicked_at ||= Time.now if message.respond_to?(:clicked_at=)
        message.save! if message.changed?
      end
    end
  end
end
