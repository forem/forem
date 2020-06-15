class EmailSignupsController < ApplicationController
  before_action :authenticate_user!

  def create
    # rate_limit!(:email_signup_creation)

    source_type = email_signup_params[:source_type]
    return invalid_type_error unless UserSubscription::ALLOWED_TYPES.include?(source_type)

    source_id = email_signup_params[:source_id]
    user_subscription_sourceable = source_type.safe_constantize.find_by(id: source_id)
    return user_subscription_sourceable_not_found unless user_subscription_sourceable

    return email_signup_tag_not_enabled unless email_signup_tag_enabled?(user_subscription_sourceable)

    @user_subscription = UserSubscription.new(
      user_subscription_sourceable: user_subscription_sourceable,
      subscriber: current_user,
      author_id: user_subscription_sourceable.user_id,
    )

    if @user_subscription.save
      # rate_limiter.track_limit_by_action(:email_signup_creation)
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

  def user_subscription_sourceable_not_found
    render json: { error: "source not found", status: 422 },
           status: :unprocessable_entity
  end

  def email_signup_tag_not_enabled
    render json: {
      error: "email signups are not enabled for the requested source",
      status: 422
    }, status: :unprocessable_entity
  end

  def email_signup_tag_enabled?(user_subscription_sourceable)
    liquid_tags =
      case email_signup_params[:source_type]
      when "Article"
        user_subscription_sourceable.liquid_tags_used(:body)
      else
        user_subscription_sourceable.liquid_tags_used
      end

    liquid_tags.include?(EmailSignupTag)
  end

  def email_signup_params
    accessible = %i[source_type source_id]
    params.require(:email_signup).permit(accessible)
  end
end
