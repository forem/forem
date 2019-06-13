class NotificationSubscriptionsController < ApplicationController
  def show
    result = if current_user
               NotificationSubscription.exists?(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type])
             else
               false
             end
    respond_to do |format|
      format.json { render json: result }
    end
  end

  def upsert
    not_found unless current_user

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
  end

  private

  def current_user_is_author?
    # TODO: think of a better solution for handling mute notifications in dashboard / manage
    current_user.id == @notification_subscription.notifiable.user_id
  end
end
