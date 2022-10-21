class DisplayAdEventsController < ApplicationMetalController
  include ActionController::Head
  # No policy needed. All views are for all users

  def create
    # Only tracking for logged in users at the moment
    display_ad_event_create_params = display_ad_event_params.merge(user_id: session_current_user_id)
    @display_ad_event = DisplayAdEvent.create(display_ad_event_create_params)

    update_display_ads_data

    head :ok
  end

  private

  def update_display_ads_data
    ThrottledCall.perform(:display_ads_data_update, throttle_for: 15.minutes) do
      @display_ad = DisplayAd.find(display_ad_event_params[:display_ad_id])

      num_impressions = @display_ad.display_ad_events.impressions.sum(:counts_for)
      num_clicks = @display_ad.display_ad_events.clicks.sum(:counts_for)
      rate = num_clicks.to_f / num_impressions

      @display_ad.update_columns(
        success_rate: rate,
        clicks_count: num_clicks,
        impressions_count: num_impressions,
      )
    end
  end

  def display_ad_event_params
    params[:display_ad_event].slice(:context_type, :category, :display_ad_id)
  end
end
