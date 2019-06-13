class NotificationSubscriptionsController < ApplicationController
  def show
    not_found unless current_user

    result = NotificationSubscription.exists?(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type])
    respond_to do |format|
      format.json { render json: result }
    end
  end

  def upsert
    not_found unless current_user
    raise RateLimitChecker::UploadRateLimitReached if RateLimitChecker.new(current_user).limit_by_situation("notification_subscriptions")

    @notification_subscription = NotificationSubscription.find_or_initialize_by(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type].capitalize)
    if params[:currently_subscribed] == "true"
      @notification_subscription.notifiable.update(receive_notifications: false) if current_user_is_author?
      @notification_subscription.delete
    elsif params[:currently_subscribed] == "false"
      @notification_subscription.notifiable.update(receive_notifications: true) if current_user_is_author?
      @notification_subscription.save!
    end

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

  def current_user_is_author?
    # TODO: think of a better solution for handling mute notifications in dashboard / manage
    current_user.id == @notification_subscription.notifiable.user_id
  end
end
