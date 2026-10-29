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

  # Client-side needs this to be idempotent-ish, return existing subscription instead
  # of raising uniqueness exception
  def create
    authorize :comment, :subscribe?

    subscription_config = params[:subscription_config].presence || "all_comments"
    subscriber = NotificationSubscriptions::Subscribe.call(current_user,
                                                           article_id: params[:article_id].presence,
                                                           comment_id: params[:comment_id].presence,
                                                           config: subscription_config)

    render json: subscriber, status: :ok
  end

  def destroy
    authorize :comment, :unsubscribe?
    unsubscriber = NotificationSubscriptions::Unsubscribe.call(current_user, params[:subscription_id])

    render json: unsubscriber, status: :ok
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
      save_subscription
    end

    respond_to do |format|
      format.json { render json: @notification_subscription.persisted? }
      format.html { redirect_to request.referer }
    end
  end

  private

  # A concurrent upsert (e.g. a double click) can insert the same subscription between our
  # lookup and INSERT; update the row it created instead of failing the uniqueness validation
  # or raising on the unique index.
  def save_subscription
    return true if @notification_subscription.save

    errors = @notification_subscription.errors
    return false unless errors.count == 1 && errors.of_kind?(:user_id, :taken)

    update_concurrent_subscription
  rescue ActiveRecord::RecordNotUnique
    update_concurrent_subscription
  end

  def update_concurrent_subscription
    config = @notification_subscription.config
    @notification_subscription = NotificationSubscription.uncached do
      NotificationSubscription.find_by!(
        @notification_subscription.slice(:user_id, :notifiable_id, :notifiable_type),
      )
    end
    @notification_subscription.update(config: config)
  end

  def current_user_author?
    # TODO: think of a better solution for handling mute notifications in dashboard / manage
    current_user.id == @notification_subscription.notifiable.user_id
  end
end
