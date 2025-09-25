module Users
  class CancelStripeSubscriptions
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return unless user&.stripe_id_code.present?

      cancel_all_subscriptions
    rescue StandardError => e
      # Log the error but don't raise it to prevent account deletion from failing
      Rails.logger.error "Failed to cancel Stripe subscriptions for user #{user.id}: #{e.message}"
      ForemStatsClient.increment("users.stripe_subscription_cancellation_failed", tags: ["user_id:#{user.id}"])
      Honeybadger.notify(e, context: { user_id: user.id, stripe_id_code: user.stripe_id_code })
    end

    private

    attr_reader :user

    def cancel_all_subscriptions
      # Set Stripe API key
      Stripe.api_key = Settings::General.stripe_api_key

      # Get all subscriptions for the customer
      subscriptions = Stripe::Subscription.list(customer: user.stripe_id_code, status: "active")

      subscriptions.data.each do |subscription|
        cancel_subscription(subscription)
      end
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Stripe invalid request error for user #{user.id}: #{e.message}"
      # Don't re-raise - this could be due to customer not existing in Stripe
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error for user #{user.id}: #{e.message}"
      # Don't re-raise - let account deletion continue
    end

    def cancel_subscription(subscription)
      # Cancel the subscription immediately (not at period end)
      Stripe::Subscription.update(subscription.id, {
        cancel_at_period_end: false
      })
      
      Rails.logger.info "Successfully cancelled Stripe subscription #{subscription.id} for user #{user.id}"
      ForemStatsClient.increment("users.stripe_subscription_cancelled", tags: ["user_id:#{user.id}"])
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Failed to cancel subscription #{subscription.id} for user #{user.id}: #{e.message}"
      # Continue with other subscriptions even if one fails
    end
  end
end
