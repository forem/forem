class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  USER_SUBSCRIPTION_PARAMS = %i[source_type source_id subscriber_email].freeze

  def subscribed
    params.require(%i[source_type source_id])
    is_subscribed = UserSubscriptions::SubscriptionCacheChecker.call(current_user, params)

    render json: { is_subscribed: is_subscribed, success: true }, status: :ok
  end

  def create
    rate_limit!(:user_subscription_creation)

    source_type = user_subscription_params[:source_type]
    return error_response("Invalid source_type.") unless UserSubscription::ALLOWED_TYPES.include?(source_type)

    source_id = user_subscription_params[:source_id]
    source = source_type.constantize.find_by(id: source_id)
    return error_response("Source not found.") unless source

    # TODO: [@thepracticaldev/delightful]: uncomment this once email confirmation is re-enabled
    # return error_response("Subscriber email mismatch.") unless subscriber_email_is_current

    user_subscription = source.build_user_subscription(current_user)

    if user_subscription.save
      rate_limiter.track_limit_by_action(:user_subscription_creation)
      render json: { message: "success", success: true }, status: :ok
    else
      error_response(user_subscription.errors.full_messages.to_sentence)
    end
  end

  private

  # This checks if the email address the user saw/consented to share is the
  # same as their current email address. A mismatch occurs if a user updates
  # their email address in a new/separate tab and then tries to subscribe on
  # the old/stale tab without refreshing. In that case, the user would have
  # consented to share their old email address instead of the current one.
  def subscriber_email_is_current
    current_user.email == user_subscription_params[:subscriber_email]
  end

  def error_response(msg)
    render json: { error: msg, success: false }, status: :unprocessable_entity
  end

  def user_subscription_params
    params.require(:user_subscription).permit(USER_SUBSCRIPTION_PARAMS)
  end
end
