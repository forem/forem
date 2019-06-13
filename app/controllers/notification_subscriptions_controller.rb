class NotificationSubscriptionsController < ApplicationController
  def show
    result = NotificationSubscription.exists?(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type])
    respond_to do |format|
      format.json { render json: result }
    end
  end

  def upsert
    raise RateLimitChecker::UploadRateLimitReached if RateLimitChecker.new(current_user).limit_by_situation("notification_subscription")

    @notification_subscription = NotificationSubscription.find_or_initialize_by(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type].capitalize)
    if params[:subscription_status] == "true"
      @notification_subscription.notifiable.update(receive_notifications: false) if current_user_is_author_and_notifiable_is_article?
      @notification_subscription.delete
    else
      @notification_subscription.notifiable.update(receive_notifications: true) if current_user_is_author_and_notifiable_is_article?
      @notification_subscription.save!
    end

    count = Rails.cache.read("#{current_user.id}_notification_subscription").to_i
    count += 1
    Rails.cache.write("#{current_user.id}_notification_subscription", count, expires_in: 30.seconds)

    result = @notification_subscription.persisted?
    respond_to do |format|
      format.json { render json: result }
      format.html { redirect_to request.referer }
    end
  rescue RateLimitChecker::UploadRateLimitReached
    respond_to do |format|
      format.json { render json: "Subscription rate limit reached".to_json }
    end
  end

  private

  def current_user_is_author_and_notifiable_is_article?
    # TODO: think of a better solution for handling mute notifications in dashboard / manage
    current_user.id == @notification_subscription.notifiable.user_id && @notification_subscription.notifiable_type == "Article"
  end
end
