class AnalyticsController < ApplicationController
  caches_action :index,
    cache_path: Proc.new { "#{request.params}___#{current_user.id}" },
    expires_in: 12.minutes
  after_action :verify_authorized

  def index
    @article_ids = analytics_params.split(",")
    articles_to_check = Article.where(id: @article_ids)
    authorize articles_to_check, :analytics_index?

    qualified_articles = get_articles_that_qualify(articles_to_check)
    fetch_and_update_page_views_and_reaction_counts(qualified_articles)

    render_finalized_json
  end

  def get_articles_that_qualify(articles_to_check)
    qualified_articles = []
    articles_to_check.each do |article|
      if article.positive_reactions_count > article.previous_positive_reactions_count
        qualified_articles << article
      end
    end
    qualified_articles
  end

  def fetch_and_update_page_views_and_reaction_counts(qualified_articles)
    pageviews = GoogleAnalytics.new(qualified_articles.pluck(:id)).get_pageviews
    page_views_obj = pageviews.to_h
    qualified_articles.each do |article|
      article.update_columns(page_views_count: page_views_obj[article.id],
                             previous_positive_reactions_count: article.positive_reactions_count)
    end
  end

  def render_finalized_json
    finalized_object = {}
    Article.where(id: @article_ids).
      pluck(:id, :page_views_count).map { |a| finalized_object[a[0]] = a[1].to_s }
    render json: finalized_object.to_json
  end

  private

  def analytics_params
    params.require(:article_ids)
  end
end
