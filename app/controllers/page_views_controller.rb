class PageViewsController < ApplicationController
  # No policy needed. All views are for all users
  def create
    if user_signed_in?
      PageView.create(user_id: current_user.id,
                      article_id: page_view_params[:article_id],
                      referrer: page_view_params[:referrer],
                      user_agent: page_view_params[:user_agent])
    else
      PageView.create(counts_for_number_of_views: 10,
                      article_id: page_view_params[:article_id],
                      referrer: page_view_params[:referrer],
                      user_agent: page_view_params[:user_agent])
    end
    update_article_page_views
    head :ok
  end

  def update
    if user_signed_in?
      page_view = PageView.where(article_id: params[:id], user_id: current_user.id).last
      page_view.update_column(:time_tracked_in_seconds, page_view.time_tracked_in_seconds + 15)
    end
    head :ok
  end

  private

  def update_article_page_views
    return if Rails.env.production? && rand(5) != 1 # We don't need to update the article page views every time.

    article = Article.find(page_view_params[:article_id])
    new_page_views_count = article.page_views.sum(:counts_for_number_of_views)
    article.update_column(:page_views_count, new_page_views_count) if new_page_views_count > article.page_views_count
  end

  def page_view_params
    params.require(:page_view).permit(%i[article_id referrer user_agent])
  end
end
