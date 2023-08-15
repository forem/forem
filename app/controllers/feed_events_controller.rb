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
      options = single_feed_event_params.merge(user_id: session_current_user_id)
      FeedEvent.create(options)
    end

    head :ok
  end

  private

  def single_feed_event_params
    @single_feed_event_params ||= params[:feed_event]&.slice(*FEED_EVENT_ALLOWED_PARAMS)
  end
end
