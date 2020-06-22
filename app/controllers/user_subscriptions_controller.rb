class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def subscribed
    params.require(%i[source_type source_id])
    source_type = params[:source_type]
    source_id = params[:source_id]

    is_subscribed = UserSubscriptions::CacheChecker.new(current_user, source_type, source_id).cached_subscription_check

    render json: {
      is_subscribed: is_subscribed,
      status: 200
    }, status: :ok
  end

  def create
    rate_limit!(:user_subscription_creation)

    source_type = user_subscription_params[:source_type]
    return error_response("invalid source_type") unless UserSubscription::ALLOWED_TYPES.include?(source_type)

    source_id = user_subscription_params[:source_id]
    user_subscription_source = source_type.constantize.find_by(id: source_id)
    return error_response("source not found") unless active_source?(source_type, user_subscription_source)

    unless user_subscription_tag_enabled?(source_type, user_subscription_source)
      return error_response("user subscriptions are not enabled for the requested source")
    end

    return error_response("subscriber email mismatch") if subscriber_email_stale?

    @user_subscription = user_subscription_source.build_user_subscription(current_user)

    if @user_subscription.save
      rate_limiter.track_limit_by_action(:user_subscription_creation)
      render json: { message: "success", status: 200 }, status: :ok
    else
      error_response(@user_subscription.errors.full_messages.to_sentence)
    end
  end

  private

  def user_subscription_tag_enabled?(source_type, user_subscription_source)
    liquid_tags =
      case source_type
      when "Article"
        user_subscription_source.liquid_tags_used(:body)
      else
        user_subscription_source.liquid_tags_used
      end

    liquid_tags.include?(UserSubscriptionTag)
  end

  def active_source?(source_type, user_subscription_source)
    return false unless user_subscription_source

    # Don't create new user subscriptions for inactive sources
    # (i.e. unpublished Articles, deleted Comments, etc.)
    case source_type
    when "Article"
      user_subscription_source.published?
    else
      false
    end
  end

  def error_response(msg)
    render json: { error: msg, status: 422 }, status: :unprocessable_entity
  end

  # This checks if the email address the user saw/consented to share is the
  # same as their current email address. A mismatch occurs if a user updates
  # their email address in a new/separate tab and then tries to subscribe on
  # the old/stale tab without refreshing. In that case, the user would have
  # consented to share their old email address instead of the current one.
  def subscriber_email_stale?
    current_user&.email != user_subscription_params[:subscriber_email]
  end

  def user_subscription_params
    accessible = %i[source_type source_id subscriber_email]
    params.require(:user_subscription).permit(accessible)
  end
end
