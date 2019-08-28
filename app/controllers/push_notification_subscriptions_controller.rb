class PushNotificationSubscriptionsController < ApplicationController
  def create
    @subscription = PushNotificationSubscription.where(endpoint: pns_params[:endpoint]).
      first_or_create(
        auth_key: pns_params[:keys][:auth],
        p256dh_key: pns_params[:keys][:p256dh],
        endpoint: pns_params[:endpoint],
        user_id: current_user.id,
        notification_type: "browser",
      )
    render json: { status: "success", endpoint: @subscription.endpoint }, status: :created
  end

  private

  def pns_params
    params.require(:subscription).permit({ keys: %i[auth p256dh] }, :endpoint)
  end
end
