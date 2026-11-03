class FeedEventsController < ApplicationMetalController
  before_action :current_user_by_token, only: [:create]
  skip_forgery_protection if: :token_authenticated?
  include ActionController::Head

  FEED_EVENT_ALLOWED_PARAMS = %i[
    article_id
    article_position
    category
    context_type
    feed_config_id
    event_id
  ].freeze

  MAX_BATCH_SIZE = 20
  REQUESTS_PER_MINUTE = 120

  def create
    return head :ok unless session_current_user_id
    return head :ok if FeatureFlag.enabled?(:disable_browser_feed_events)
    return head :bad_request unless params[:feed_events].is_a?(Array)
    return head :payload_too_large if params[:feed_events].size > MAX_BATCH_SIZE
    return head :bad_request unless valid_batch?

    if Rack::Attack.cache.count("feed_events/user/#{session_current_user_id}", 60) > REQUESTS_PER_MINUTE
      response.headers["Retry-After"] = "60"
      return head :too_many_requests
    end

    FeedEvents::BulkUpsert.call(feed_events_params)
    head :ok
  end

  private

  def valid_batch?
    params[:feed_events].all? { |event| event.is_a?(ActionController::Parameters) || event.is_a?(Hash) }
  end

  def feed_events_params
    @feed_events_params ||= params[:feed_events].map do |event|
      event.slice(*FEED_EVENT_ALLOWED_PARAMS).merge(user_id: session_current_user_id)
    end
  end
end
