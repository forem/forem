class FeedEventsController < ApplicationMetalController
  include ActionController::Head

  FEED_EVENT_ALLOWED_PARAMS = %i[
    article_id
    article_position
    category
    context_type
  ].freeze

  def create
    if session_current_user_id
      FeedEvents::BulkUpsert.call(feed_events_params)
    end

    head :ok
  end

  private

  def feed_events_params
    @feed_events_params ||= params[:feed_events].map do |event|
      event.slice(*FEED_EVENT_ALLOWED_PARAMS).merge(user_id: session_current_user_id)
    end
  end
end
