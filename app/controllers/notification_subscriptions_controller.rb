class NotificationSubscriptionsController < ApplicationController
  def show
    result = NotificationSubscription.exists?(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type])
    respond_to do |format|
      format.json { render json: result }
    end
  end

  def upsert
    raise RateLimitChecker::UploadRateLimitReached if RateLimitChecker.new(current_user).limit_by_situation("notification_subscription")

    @notification_subscription = NotificationSubscription.find_or_initialize_by(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type])
    if params[:subscription_status] == "true"
      @notification_subscription.delete
    else
      @notification_subscription.save!
    end

    count = Rails.cache.read("#{current_user.id}_notification_subscription").to_i
    count += 1
    Rails.cache.write("#{current_user.id}_notification_subscription", count, expires_in: 30.seconds)

    result = @notification_subscription.persisted?
    respond_to do |format|
      format.json { render json: result }
    end
  rescue RateLimitChecker::UploadRateLimitReached
    respond_to do |format|
      format.json { render json: "Subscription rate limit reached".to_json }
    end
  end
end
