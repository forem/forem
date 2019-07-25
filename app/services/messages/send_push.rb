module Messages
  class SendPush
    def initialize(user, chat_channel, message_html)
      @user = user
      @chat_channel = chat_channel
      @message_html = message_html
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      receivers = chat_channel.chat_channel_memberships.where.not(user_id: user.id).select(:user_id)
      PushNotificationSubscription.where(user_id: receivers).find_each do |sub|
        break if no_push_necessary?(sub)

        Webpush.payload_send(
          endpoint: sub.endpoint,
          message: ActionView::Base.full_sanitizer.sanitize(message_html),
          p256dh: sub.p256dh_key,
          auth: sub.auth_key,
          ttl: 24 * 60 * 60,
          vapid: {
            subject: "https://dev.to",
            public_key: ApplicationConfig["VAPID_PUBLIC_KEY"],
            private_key: ApplicationConfig["VAPID_PRIVATE_KEY"]
          },
        )
      end
    end

    private

    attr_reader :user, :chat_channel, :message_html

    def no_push_necessary?(sub)
      membership = sub.user.chat_channel_memberships.order("last_opened_at DESC").first
      membership.last_opened_at > 40.seconds.ago
    end
  end
end
