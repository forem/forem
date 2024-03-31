module NotificationSubscriptions
  class Update
    def self.call(...)
      new(...).call
    end

    def initialize(notifiable)
      @notifiable = notifiable
    end

    def call
      return unless [Article].include?(notifiable.class)

      notification_subscriptions = NotificationSubscription.where(
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
      )

      return if notification_subscriptions.none?

      notification_subscriptions.update_all(user_id: notifiable.user_id)
    end

    private

    attr_reader :notifiable
  end
end
