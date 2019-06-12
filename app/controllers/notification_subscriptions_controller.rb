class NotificationSubscriptionsController < ApplicationController
  def show
    result = NotificationSubscription.exists?(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type])
    respond_to do |format|
      format.json { render json: result }
    end
  end

  def upsert
    @notification_subscription = NotificationSubscription.find_or_initialize_by(user_id: current_user.id, notifiable_id: params[:notifiable_id], notifiable_type: params[:notifiable_type])
    if params[:subscription_status] == "true"
      @notification_subscription.delete
    else
      @notification_subscription.save!
    end
    result = @notification_subscription.persisted?
    respond_to do |format|
      format.json { render json: result }
    end
  end
end
