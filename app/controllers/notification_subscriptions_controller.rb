class NotificationSubscriptionsController < ApplicationController
  def show
    result = if current_user
               NotificationSubscription.where(user_id: current_user.id, notifiable_id: params[:notifiable_id],
                                              notifiable_type: params[:notifiable_type])
                 .first&.to_json(only: %i[config]) || { config: "not_subscribed" }
             end
    respond_to do |format|
      format.json { render json: result }
    end
  end

  def upsert
    not_found unless current_user

    @notification_subscription = NotificationSubscription.find_or_initialize_by(
      user_id: current_user.id,
      notifiable_id: params[:notifiable_id],
      notifiable_type: params[:notifiable_type].capitalize,
    )

    if params[:config] == "not_subscribed"
      @notification_subscription.delete
      @notification_subscription.notifiable.update(receive_notifications: false) if current_user_author?
    else
      @notification_subscription.config = params[:config] || "all_comments"
      receive_notifications = (params[:config] == "all_comments" && current_user_author?)
      @notification_subscription.notifiable.update(receive_notifications: true) if receive_notifications
      @notification_subscription.save
    end

    respond_to do |format|
      format.json { render json: @notification_subscription.persisted? }
      format.html { redirect_to request.referer }
    end
  end

  private

  def current_user_author?
    # TODO: think of a better solution for handling mute notifications in dashboard / manage
    current_user.id == @notification_subscription.notifiable.user_id
  end
end
