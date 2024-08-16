class PageViewsController < ApplicationMetalController
  # ApplicationMetalController because we do not need all bells and whistles of ApplicationController.
  # It should help performance.
  include ActionController::Head

  # Each time we have a non-authenticated visitor, we have a 10% chance that we will record that
  # specific impression as a page view.  When we do record that specific impression as a page view,
  # we want to give credit for all likely page views that we didn't record (e.g., the 90% or so).
  #
  # @note Yes, this is a very verbose constant name.  Apologies, don't type it.  But I [@jeremyf]
  #       want it here to explain a magic number.
  #
  # @see https://github.com/forem/forem/blob/main/app/assets/javascripts/initializers/initializeBaseTracking.js.erb#L113-L117
  # @see https://github.com/forem/forem/pull/12686#discussion_r577271589 for further discussion.
  VISITOR_IMPRESSIONS_AGGREGATE_COUNTS_FOR_NUMBER_OF_VIEWS = 10

  def create
    page_view_create_params = params.slice(:article_id, :referrer, :user_agent)
    if session_current_user_id
      page_view_create_params[:user_id] = session_current_user_id
    else
      page_view_create_params[:counts_for_number_of_views] = VISITOR_IMPRESSIONS_AGGREGATE_COUNTS_FOR_NUMBER_OF_VIEWS
    end

    Articles::UpdatePageViewsWorker.perform_at(
      2.minutes.from_now,
      page_view_create_params,
    )

    send_algolia_insight
    head :ok
  end

  def update
    if session_current_user_id
      Articles::PageViewUpdater.call(article_id: params[:id], user_id: session_current_user_id)
    end

    head :ok
  end

  private

  def send_algolia_insight
    return unless session_current_user_id &&
      Settings::General.algolia_application_id.present? &&
      Settings::General.algolia_api_key.present?

    AlgoliaInsightsService.new.track_event(
      "view",
      "Article Viewed",
      session_current_user_id,
      params[:article_id].to_i,
      "Article_#{Rails.env}",
      Time.current.to_i * 1000,
    )
  end
end
