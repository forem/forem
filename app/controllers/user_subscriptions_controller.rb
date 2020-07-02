class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  USER_SUBSCRIPTION_PARAMS = %i[source_type source_id subscriber_email].freeze

  def subscribed
    params.require(%i[source_type source_id])
    is_subscribed = UserSubscriptions::IsSubscribedCacheChecker.call(current_user, params)

    render json: { is_subscribed: is_subscribed, success: true }, status: :ok
  end

  def create
    rate_limit!(:user_subscription_creation)

    user_subscription = UserSubscriptions::CreateFromControllerParams.call(current_user, user_subscription_params)

    if user_subscription.success
      rate_limiter.track_limit_by_action(:user_subscription_creation)
      render json: { message: "success", success: true }, status: :ok
    else
      render json: { error: user_subscription.error, success: false }, status: :unprocessable_entity
    end
  end

  def user_subscription_params
    params.require(:user_subscription).permit(USER_SUBSCRIPTION_PARAMS)
  end
end
