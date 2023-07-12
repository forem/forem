module NotificationSubscriptions
  class Unsubscribe
    attr_reader :current_user, :subscription_id

    def self.call(...)
      new(...).call
    end

    def initialize(current_user, subscription_id)
      @current_user = current_user
      @subscription_id = subscription_id
    end

    def call
      unsubscribe_subscription
    end

    def unsubscribe_subscription
      return { errors: "Notification subscription not found" } if subscription.nil?

      subscription.destroy

      if subscription.destroyed?
        bust_caches
        { destroyed: true }
      else
        { errors: subscription.errors_as_sentence }
      end
    end

    private

    def bust_caches
      Notifications::BustCaches.call(user: current_user, notifiable: notifiable)
    end

    def notifiable
      subscription&.notifiable
    end

    def subscription
      return if subscription_id.nil?

      @subscription ||= NotificationSubscription.find_by(user_id: current_user.id,
                                                         id: subscription_id)
    end
  end
end
