class BillboardEventsController < ApplicationMetalController
  include ActionController::Head
  SIGNUP_SUCCESS_MODIFIER = 25 # One signup is worth 25 clicks
  # No policy needed. All views are for all users

  def create
    # Only tracking for logged in users at the moment
    billboard_event_create_params = billboard_event_params.merge(user_id: session_current_user_id)
    @billboard_event = BillboardEvent.create(billboard_event_create_params)

    update_billboards_data

    head :ok
  end

  private

  def update_billboards_data
    billboard_event_id = billboard_event_params[:billboard_id]

    ThrottledCall.perform("billboards_data_update-#{billboard_event_id}", throttle_for: 25.minutes) do
      @billboard = Billboard.find(billboard_event_id)
      aggregates = @billboard.billboard_events.select(
        'SUM(CASE WHEN event_type = \'impressions\' THEN counts_for ELSE 0 END) AS total_impressions',
        'SUM(CASE WHEN event_type = \'clicks\' THEN counts_for ELSE 0 END) AS total_clicks',
        'SUM(CASE WHEN event_type = \'signups\' THEN counts_for ELSE 0 END) * ? AS signup_success',
        SIGNUP_SUCCESS_MODIFIER
      ).first

      num_impressions = aggregates.total_impressions.to_i
      num_clicks = aggregates.total_clicks.to_i
      signup_success = aggregates.signup_success.to_f

      # Ensure num_impressions is not zero to avoid division by zero error
      rate = num_impressions > 0 ? (num_clicks + signup_success) / num_impressions.to_f : 0

      # Update the billboard record
      @billboard.update_columns(
        success_rate: rate,
        clicks_count: num_clicks,
        impressions_count: num_impressions,
      )
    end
  end

  def billboard_event_params
    event_params = params[:billboard_event] || params[:display_ad_event]
    # keeping while we may receive data in the "old" format from cached js
    billboard_id = event_params.delete(:display_ad_id)
    event_params[:billboard_id] ||= billboard_id
    event_params[:article_id] = params[:article_id] if params[:article_id].present?
    event_params[:geolocation] = client_geolocation
    event_params.slice(:context_type, :category, :billboard_id, :article_id, :geolocation)
  end
end
