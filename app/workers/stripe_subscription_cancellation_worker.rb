class StripeSubscriptionCancellationWorker
  include Sidekiq::Job

  sidekiq_options queue: :low_priority, retry: 3

  def perform(user_id, stripe_id_code)
    return if stripe_id_code.blank?

    Stripe.api_key = Settings::General.stripe_api_key
    
    # List all subscriptions for the customer
    subscriptions = Stripe::Subscription.list(customer: stripe_id_code)
    
    subscriptions.data.each do |subscription|
      # Only cancel active subscriptions
      next unless subscription.status.in?(%w[active trialing past_due])
      
      Rails.logger.info("Canceling Stripe subscription #{subscription.id} for user #{user_id}")
      
      # Cancel the subscription immediately
      Stripe::Subscription.update(subscription.id, {
        cancel_at_period_end: false
      })
    end
    
    Rails.logger.info("Successfully canceled all Stripe subscriptions for user #{user_id}")
    
  rescue Stripe::InvalidRequestError => e
    # Customer or subscription not found - this is expected if already deleted
    Rails.logger.info("Stripe customer/subscription not found for user #{user_id}: #{e.message}")
  rescue Stripe::StripeError => e
    # Other Stripe errors - log but don't fail the job
    Rails.logger.error("Stripe error canceling subscriptions for user #{user_id}: #{e.message}")
    raise e if attempts < 3 # Retry up to 3 times for Stripe errors
  rescue StandardError => e
    # Any other errors - log but don't fail user deletion
    Rails.logger.error("Unexpected error canceling Stripe subscriptions for user #{user_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end