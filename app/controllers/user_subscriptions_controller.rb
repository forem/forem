class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  USER_SUBSCRIPTION_PARAMS = %i[source_type source_id subscriber_email].freeze

  def subscribed
    params.require(%i[source_type source_id])
    source_type = params[:source_type]
    source_id = params[:source_id]

    is_subscribed = UserSubscriptions::SubscriptionCacheChecker.call(current_user, source_type, source_id)

    render json: { is_subscribed: is_subscribed, success: true }, status: :ok
  end

  def create
    rate_limit!(:user_subscription_creation)

    source_type = user_subscription_params[:source_type]
    return error_response("invalid source_type") unless UserSubscription::ALLOWED_TYPES.include?(source_type)

    source_id = user_subscription_params[:source_id]
    source = source_type.constantize.find_by(id: source_id)
    return error_response("source not found") unless source

    user_subscription = source.build_user_subscription(current_user)

    if user_subscription.save
      rate_limiter.track_limit_by_action(:user_subscription_creation)
      render json: { message: "success", success: true }, status: :ok
    else
      error_response(user_subscription.errors.full_messages.to_sentence)
    end
  end

  private

  def error_response(msg)
    render json: { error: msg, success: false }, status: :unprocessable_entity
  end

  def user_subscription_params
    params.require(:user_subscription).permit(USER_SUBSCRIPTION_PARAMS)
  end
end
