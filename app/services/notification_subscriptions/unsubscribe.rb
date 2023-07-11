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
      return { errors: "Subscription ID is missing" } if subscription_id.nil?

      notification = NotificationSubscription.find_by(user_id: current_user.id,
                                                      id: subscription_id)
      return { errors: "Notification subscription not found" } if notification.nil?

      destroy_notification(notification)
    end

    private

    def destroy_notification(notification)
      notification.destroy

      if notification.destroyed?
        { destroyed: true }
      else
        { errors: notification.errors_as_sentence }
      end
    end
  end
end
