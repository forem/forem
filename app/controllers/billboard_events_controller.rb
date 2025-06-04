# app/controllers/billboard_events_controller.rb
class BillboardEventsController < ApplicationMetalController
  include ActionController::Head

  def create
    # Only tracking for logged‐in users at the moment
    billboard_event_create_params = billboard_event_params.merge(user_id: session_current_user_id)
    @billboard_event = BillboardEvent.create(billboard_event_create_params)

    unless ApplicationConfig["DISABLE_BILLBOARD_DATA_UPDATE"] == "yes"
      # Enqueue the worker instead of doing the update inline
      Billboards::DataUpdateWorker.perform_async(billboard_event_params[:billboard_id])
    end

    head :ok
  end

  private

  def billboard_event_params
    event_params = params[:billboard_event] || params[:display_ad_event]
    # Keeping while we may receive data in the "old" format from cached JS
    billboard_id = event_params.delete(:display_ad_id)
    event_params[:billboard_id] ||= billboard_id
    event_params[:article_id] = params[:article_id] if params[:article_id].present?
    event_params[:geolocation] = client_geolocation
    event_params.slice(:context_type, :category, :billboard_id, :article_id, :geolocation)
  end
end
