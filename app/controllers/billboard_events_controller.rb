# app/controllers/billboard_events_controller.rb
class BillboardEventsController < ApplicationMetalController
  include ActionController::Head
  THROTTLE_TIME = 25 # minutes

  # Embedding sites (Billboard.embed_origins) send events cross-origin without cookies, so there
  # is no session to forge and their events are always anonymous.
  skip_forgery_protection if: :embed_request?

  def create
    # Only tracking for logged‐in users at the moment
    user_id = embed_request? ? nil : session_current_user_id
    billboard_event_create_params = billboard_event_params.merge(user_id: user_id)
    return head :ok if billboard_event_create_params[:billboard_id].blank?

    @billboard_event = ApplicationRecord.with_synchronous_commit_off do
      BillboardEvent.create(billboard_event_create_params.except(:billboard_id)
        .merge(billboard: billboard_for_event(billboard_event_create_params[:billboard_id])))
    end

    unless ApplicationConfig["DISABLE_BILLBOARD_DATA_UPDATE"] == "yes"
      # Enqueue the worker instead of doing the update inline
      throttle_minutes = (ApplicationConfig["BILLBOARD_EVENT_THROTTLE_TIME"] || THROTTLE_TIME).to_i
      throttle_key = "billboards_data_update-#{billboard_event_create_params[:billboard_id]}"
      ThrottledCall.perform(throttle_key, throttle_for: throttle_minutes.minutes) do
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
    current_user_id = session_current_user_id
    rows_updated = BillboardEvent.add_impression_seconds(id: params[:id], user_id: current_user_id)

    return head :ok if rows_updated.positive?

    @billboard_event = BillboardEvent.select(:id, :category, :user_id, :updated_at).find_by(id: params[:id])
    return head :not_found unless @billboard_event
    return head :ok unless @billboard_event.category == BillboardEvent::CATEGORY_IMPRESSION

    if @billboard_event.user_id && @billboard_event.user_id != current_user_id
      return head :forbidden
    end

    head :too_many_requests
  end

  private

  # The required belongs_to :billboard check would load the whole billboard row (body, html and
  # targeting arrays) on every event. Only its existence matters here, so look up just the id,
  # cast exactly as assigning display_ad_id would. A missing billboard still fails validation.
  def billboard_for_event(raw_billboard_id)
    billboard_id = BillboardEvent.type_for_attribute(:display_ad_id).cast(raw_billboard_id)
    Billboard.select(:id).find_by(id: billboard_id) if billboard_id
  end

  def billboard_event_params
    event_params = params[:billboard_event] || params[:display_ad_event] || ActionController::Parameters.new
    # Keeping while we may receive data in the "old" format from cached JS
    billboard_id = event_params.delete(:display_ad_id)
    event_params[:billboard_id] ||= billboard_id
    event_params[:article_id] = params[:article_id] if params[:article_id].present?
    event_params[:geolocation] = client_geolocation
    event_params[:user_agent] = event_params[:user_agent].presence || params[:user_agent].presence || request.user_agent
    event_params[:context_type] = BillboardEvent::CONTEXT_TYPE_EMBED if embed_request?
    event_params.slice(:context_type, :category, :billboard_id, :article_id, :geolocation, :user_agent)
  end

  def embed_request?
    Billboard.embed_origins.include?(request.origin)
  end
end
