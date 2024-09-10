class SidebarsController < ApplicationController
  ACTIVE_DISCUSSION_LIMIT = 8
  layout false

  def show
    get_latest_campaign_articles
    get_active_discussions if user_signed_in?
  end

  private

  def get_latest_campaign_articles
    @campaign_articles_count = Campaign.current.count
    @latest_campaign_articles = Campaign.current.plucked_article_attributes
  end

  def get_active_discussions
    tag_names = current_user.cached_followed_tag_names
    languages = current_user.languages.pluck(:language)
    languages = [I18n.default_locale.to_s] if languages.empty?
    order = Arel.sql("last_comment_at + (INTERVAL '1 minute' * LEAST(comment_score, 50)) DESC") # Determined via field test
    @active_discussions = Article.published
      .where("published_at > ?", 1.week.ago)
      .where("comments_count > ?", 0)
      .with_at_least_home_feed_minimum_score
      .cached_tagged_with_any(tag_names)
      .where(language: languages)
      .or(Article.featured.published.where("published_at > ?", 1.week.ago)
        .with_at_least_home_feed_minimum_score)
      .or(Article.where(id: cached_recent_pageview_article_ids).published
        .where("published_at > ?", 1.week.ago)
        .where("comments_count > ?", 1)
          .with_at_least_home_feed_minimum_score)
      .order(order)
      .limit(ACTIVE_DISCUSSION_LIMIT)
      .pluck(:path, :title, :comments_count, :created_at)
  end

  def cached_recent_pageview_article_ids
    Rails.cache.fetch("recent_pageviews_#{current_user.id}", expires_in: 1.hour) do
      PageView.where(user_id: current_user.id)
        .order("created_at DESC").limit(30).pluck(:article_id)
    end
  end
end
