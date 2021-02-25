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
    if session_current_user_id
      page_view = PageView.order(created_at: :desc)
        .find_or_create_by(article_id: params[:id], user_id: session_current_user_id)

      unless page_view.new_record?
        page_view.update_column(:time_tracked_in_seconds, page_view.time_tracked_in_seconds + 15)
      end
    end

    head :ok
  end
end
