class PushNotificationSubscriptionsController < ApplicationController
  def create
    @subscription = PushNotificationSubscription.where(endpoint: params[:subscription][:endpoint]).
      first_or_create(
        auth_key: params[:subscription][:keys][:auth],
        p256dh_key: params[:subscription][:keys][:p256dh],
        endpoint: params[:subscription][:endpoint],
        user_id: current_user.id,
        notification_type: "browser",
      )
    render json: { status: "success", endpoint: @subscription.endpoint }, status: 201
  end
end
