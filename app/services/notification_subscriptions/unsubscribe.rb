module NotificationSubscriptions
  class Unsubscribe
    attr_reader :current_user, :permitted_params

    def self.call(...)
      new(...).call
    end

    def initialize(current_user, permitted_params)
      @current_user = current_user
      @permitted_params = permitted_params
    end

    def call
      unsubscribe_subscription
    end

    def unsubscribe_subscription
      subscription_id = permitted_params[:subscription_id]
      unless subscription_id.nil?
        notification = NotificationSubscription.find_by(user_id: current_user.id,
                                                        id: subscription_id)
      end
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
