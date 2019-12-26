class PageViewsController < ApplicationMetalController
  # ApplicationMetalController because we do not need all bells and whistles of ApplicationController, so should help performance.
  include ActionController::Head

  def create
    page_view_create_params = if session_current_user_id
                                page_view_params.merge(user_id: session_current_user_id)
                              else
                                page_view_params.merge(counts_for_number_of_views: 10)
                              end

    PageView.create(page_view_create_params)

    update_article_page_views

    head :ok
  end

  def update
    if session_current_user_id
      page_view = PageView.order("created_at DESC").find_or_create_by(article_id: params[:id], user_id: session_current_user_id)
      unless page_view.new_record?
        page_view.update_column(:time_tracked_in_seconds, page_view.time_tracked_in_seconds + 15)
      end
    end

    head :ok
  end

  private

  def update_article_page_views
    return if Rails.env.production? && rand(15) != 1 # We don't need to update the article page views every time.

    @article = Article.find(page_view_params[:article_id])
    new_page_views_count = @article.page_views.sum(:counts_for_number_of_views)
    @article.update_column(:page_views_count, new_page_views_count) if new_page_views_count > @article.page_views_count

    update_organic_page_views
  end

  def page_view_params
    params.slice(:article_id, :referrer, :user_agent)
  end

  def update_organic_page_views
    return if Rails.env.production? && rand(100) != 1 # We need to do this operation only once in a while.

    page_views_from_google_com = @article.page_views.where(referrer: "https://www.google.com/")

    organic_count = page_views_from_google_com.sum(:counts_for_number_of_views)
    @article.update_column(:organic_page_views_count, organic_count) if organic_count > @article.organic_page_views_count

    organic_count_past_week_count = page_views_from_google_com.
      where("created_at > ?", 1.week.ago).sum(:counts_for_number_of_views)
    @article.update_column(:organic_page_views_past_week_count, organic_count_past_week_count)

    organic_count_past_month_count = page_views_from_google_com.
      where("created_at > ?", 1.month.ago).sum(:counts_for_number_of_views)
    @article.update_column(:organic_page_views_past_month_count, organic_count_past_month_count)
  end
end
