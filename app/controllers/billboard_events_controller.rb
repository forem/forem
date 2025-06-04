class BillboardEventsController < ApplicationMetalController
  include ActionController::Head
  CONVERSION_SUCCESS_MODIFIER = 25 # One signup is worth 25 clicks
  THROTTLE_TIME = 25
  # No policy needed. All views are for all users

  def create
    # Only tracking for logged in users at the moment
    billboard_event_create_params = billboard_event_params.merge(user_id: session_current_user_id)
    @billboard_event = BillboardEvent.create(billboard_event_create_params)

    unless ApplicationConfig["DISABLE_BILLBOARD_DATA_UPDATE"] == "yes"
      update_billboards_data
    end

    head :ok
  end

  private

  def update_billboards_data
    billboard_event_id = billboard_event_params[:billboard_id]
    throttle_time = (ApplicationConfig["BILLBOARD_EVENT_THROTTLE_TIME"] || THROTTLE_TIME).to_i

    ThrottledCall.perform("billboards_data_update-#{billboard_event_id}", throttle_for: throttle_time.minutes) do
      @billboard = Billboard.find(billboard_event_id)
      timestamp = Time.current
      return if rand(3) > 0 && @billboard.impressions_count > 500_000
      return if rand(2).zero? && @billboard.impressions_count > 100_000

      if @billboard.counts_tabulated_at.present? # tabulate only new events and add them to existing counts
        num_impressions = @billboard.billboard_events.impressions.where("created_at > ?", @billboard.counts_tabulated_at).sum(:counts_for)
        num_clicks = @billboard.billboard_events.clicks.where("created_at > ?", @billboard.counts_tabulated_at).sum(:counts_for)
        conversion_success = @billboard.billboard_events.all_conversion_types.where("created_at > ?", @billboard.counts_tabulated_at).sum(:counts_for) * CONVERSION_SUCCESS_MODIFIER
        rate = (@billboard.clicks_count + num_clicks + conversion_success).to_f / (@billboard.impressions_count + num_impressions)

        @billboard.update_columns(
          success_rate: rate,
          clicks_count: @billboard.clicks_count + num_clicks,
          impressions_count: @billboard.impressions_count + num_impressions,
          counts_tabulated_at: timestamp,
        )
      else
        num_impressions = @billboard.billboard_events.impressions.sum(:counts_for)
        num_clicks = @billboard.billboard_events.clicks.sum(:counts_for)
        conversion_success = @billboard.billboard_events.all_conversion_types.sum(:counts_for) * CONVERSION_SUCCESS_MODIFIER
        rate = (num_clicks + conversion_success).to_f / num_impressions
  
        @billboard.update_columns(
          success_rate: rate,
          clicks_count: num_clicks,
          impressions_count: num_impressions,
          counts_tabulated_at: timestamp,
        )  
      end
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
