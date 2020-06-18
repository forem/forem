class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    rate_limit!(:user_subscription_creation)

    source_type = user_subscription_params[:source_type]
    return invalid_type_error unless UserSubscription::ALLOWED_TYPES.include?(source_type)

    source_id = user_subscription_params[:source_id]
    user_subscription_source = source_type.safe_constantize.find_by(id: source_id)
    return user_subscription_source_not_found unless user_subscription_source

    return user_subscription_tag_not_enabled unless user_subscription_tag_enabled?(user_subscription_source)

    return stale_user_email if user_email_stale?

    @user_subscription = user_subscription_source.build_user_subscription(current_user)

    if @user_subscription.save
      rate_limiter.track_limit_by_action(:user_subscription_creation)
      render json: { message: "success", status: 200 }, status: :ok
    else
      render json: {
        error: @user_subscription.errors.full_messages.to_sentence,
        status: 422
      }, status: :unprocessable_entity
    end
  end

  private

  def invalid_type_error
    render json: {
      error: "invalid type - only #{UserSubscription::ALLOWED_TYPES.join(', ')} are permitted",
      status: 422
    }, status: :unprocessable_entity
  end

  def user_subscription_source_not_found
    render json: { error: "source not found", status: 422 },
           status: :unprocessable_entity
  end

  def user_subscription_tag_not_enabled
    render json: {
      error: "user subscriptions are not enabled for the requested source",
      status: 422
    }, status: :unprocessable_entity
  end

  def stale_user_email
    render json: {
      error: "user email mismatch",
      status: 422
    }, status: :unprocessable_entity
  end

  def user_subscription_tag_enabled?(user_subscription_source)
    liquid_tags =
      case user_subscription_params[:source_type]
      when "Article"
        user_subscription_source.liquid_tags_used(:body)
      else
        user_subscription_source.liquid_tags_used
      end

    liquid_tags.include?(UserSubscriptionTag)
  end

  # This checks if the email address the user saw/consented to share is the
  # same as their current email address. A mismatch occurs if a user updates
  # their email address in a new/separate tab and then tries to subscribe on
  # the old/stale tab without refreshing. In that case, the user would have
  # consented to share their old email address instead of the current one.
  def user_email_stale?
    current_user&.email != user_subscription_params[:user_email]
  end

  def user_subscription_params
    accessible = %i[source_type source_id user_email]
    params.require(:user_subscription).permit(accessible)
  end
end
