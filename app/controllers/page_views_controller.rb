class PageViewsController < ApplicationMetalController
  # ApplicationMetalController because we do not need all bells and whistles of ApplicationController.
  # It should help performance.
  include ActionController::Head

  def create
    page_view_create_params = params.slice(:article_id, :referrer, :user_agent)
    if session_current_user_id
      page_view_create_params[:user_id] = session_current_user_id
    else
      page_view_create_params[:counts_for_number_of_views] = 10
    end

    Articles::UpdatePageViewsWorker.perform_at(
      2.minutes.from_now,
      page_view_create_params,
    )

    head :ok
  end

  def update
    Articles::PageViewUpdater.call(article_id: params[:id], user_id: session_current_user_id) if session_current_user_id

    head :ok
  end
end
