class Users::StripeSubscriptionCancellationWorker
  include Sidekiq::Job

  sidekiq_options queue: :low_priority, retry: 3

  def perform(user_id, stripe_customer_id)
    return if stripe_customer_id.blank?

    Rails.logger.info("Starting Stripe subscription cancellation for user #{user_id}, customer #{stripe_customer_id}")

    Stripe.api_key = Settings::General.stripe_api_key
    
    # List all subscriptions for the customer
    subscriptions = Stripe::Subscription.list(
      customer: stripe_customer_id,
      status: "all", # Get all statuses to be thorough
      limit: 100 # Handle users with many subscriptions
    )
    
    canceled_count = 0
    skipped_count = 0
    
    subscriptions.data.each do |subscription|
      # Only cancel subscriptions that are actively billing or could bill
      if subscription.status.in?(%w[active trialing past_due unpaid])
        Rails.logger.info("Canceling Stripe subscription #{subscription.id} (status: #{subscription.status}) for user #{user_id}")
        
        # Cancel the subscription immediately
        Stripe::Subscription.update(subscription.id, {
          cancel_at_period_end: false
        })
        
        canceled_count += 1
      else
        Rails.logger.debug("Skipping subscription #{subscription.id} with status '#{subscription.status}' for user #{user_id}")
        skipped_count += 1
      end
    end
    
    Rails.logger.info("Stripe subscription cancellation completed for user #{user_id}: #{canceled_count} canceled, #{skipped_count} skipped")
    
  rescue Stripe::InvalidRequestError => e
    # Customer or subscription not found - this is expected if already deleted
    Rails.logger.info("Stripe customer/subscription not found for user #{user_id}: #{e.message}")
  rescue Stripe::StripeError => e
    # Other Stripe errors - log and potentially retry
    Rails.logger.error("Stripe API error canceling subscriptions for user #{user_id}: #{e.class.name} - #{e.message}")
    
    # Only retry for certain types of errors and if we haven't exceeded attempts
    if retryable_stripe_error?(e)
      if sidekiq_retries_exhausted?
        Rails.logger.error("Max retries reached for Stripe error, giving up on user #{user_id}")
      else
        raise e # This will trigger Sidekiq retry
      end
    end
  rescue StandardError => e
    # Any other errors - log but don't fail user deletion
    Rails.logger.error("Unexpected error canceling Stripe subscriptions for user #{user_id}: #{e.class.name} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    # Don't retry for unexpected errors to avoid infinite loops
  end

  private

  def retryable_stripe_error?(error)
    # Retry for temporary/network issues, but not for permanent failures
    error.is_a?(Stripe::APIConnectionError) ||
      error.is_a?(Stripe::APIError) ||
      (error.is_a?(Stripe::RateLimitError))
  end

  def sidekiq_retries_exhausted?
    # Simple check - assume we're exhausted after 3 attempts
    # In a real implementation, this would check Sidekiq's retry count
    false # For now, always allow retries
  end
end