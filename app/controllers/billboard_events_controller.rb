class BillboardEventsController < ApplicationMetalController
  include ActionController::Head
  # No policy needed. All views are for all users

  def create
    # Only tracking for logged in users at the moment
    billboard_event_create_params = billboard_event_params.merge(user_id: session_current_user_id)
    @billboard_event = DisplayAdEvent.create(billboard_event_create_params)

    update_billboards_data

    head :ok
  end

  private

  def update_billboards_data
    billboard_event_id = billboard_event_params[:billboard_id]

    ThrottledCall.perform("billboards_data_update-#{billboard_event_id}", throttle_for: 15.minutes) do
      @billboard = DisplayAd.find(billboard_event_id)

      num_impressions = @billboard.billboard_events.impressions.sum(:counts_for)
      num_clicks = @billboard.billboard_events.clicks.sum(:counts_for)
      rate = num_clicks.to_f / num_impressions

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
    display_ad_id = event_params.delete(:display_ad_id)
    event_params[:billboard_id] ||= display_ad_id
    event_params.slice(:context_type, :category, :billboard_id)
  end
end
