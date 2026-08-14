# app/controllers/billboard_events_controller.rb
class BillboardEventsController < ApplicationMetalController
  include ActionController::Head
  THROTTLE_TIME = 25 # minutes

  def create
    # Only tracking for logged‐in users at the moment
    billboard_event_create_params = billboard_event_params.merge(user_id: session_current_user_id)
    return head :ok if billboard_event_create_params[:billboard_id].blank?
    @billboard_event = ApplicationRecord.with_synchronous_commit_off do
      BillboardEvent.create(billboard_event_create_params)
    end

    unless ApplicationConfig["DISABLE_BILLBOARD_DATA_UPDATE"] == "yes"
      # Enqueue the worker instead of doing the update inline
      throttle_minutes = (ApplicationConfig["BILLBOARD_EVENT_THROTTLE_TIME"] || THROTTLE_TIME).to_i
      ThrottledCall.perform("billboards_data_update-#{billboard_event_create_params[:billboard_id]}", throttle_for: throttle_minutes.minutes) do
        Billboards::DataUpdateWorker.perform_async(billboard_event_params[:billboard_id])
      end
    end

    if @billboard_event&.persisted?
      self.status = 200
      self.content_type = "application/json"
      self.response_body = { id: @billboard_event.id }.to_json
    else
      head :ok
    end
  end

  def update
    @billboard_event = BillboardEvent.find_by(id: params[:id])
    return head :not_found unless @billboard_event
    return head :ok unless @billboard_event.category == BillboardEvent::CATEGORY_IMPRESSION

    if @billboard_event.user_id && @billboard_event.user_id != session_current_user_id
      return head :forbidden
    end

    if @billboard_event.updated_at > 9.seconds.ago
      return head :too_many_requests
    end

    ApplicationRecord.with_synchronous_commit_off do
      BillboardEvent.where(id: @billboard_event.id).update_all(["seconds_visible = seconds_visible + ?, updated_at = ?", 10, Time.current])
    end

    head :ok
  end

  private

  def billboard_event_params
    event_params = params[:billboard_event] || params[:display_ad_event] || ActionController::Parameters.new
    # Keeping while we may receive data in the "old" format from cached JS
    billboard_id = event_params.delete(:display_ad_id)
    event_params[:billboard_id] ||= billboard_id
    event_params[:article_id] = params[:article_id] if params[:article_id].present?
    event_params[:geolocation] = client_geolocation
    event_params.slice(:context_type, :category, :billboard_id, :article_id, :geolocation)
  end
end
