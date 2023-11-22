class SidebarsController < ApplicationController
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
    @active_discussions = Article.published
      .where("published_at > ?", 1.week.ago)
      .where("comments_count > ?", 0)
      .with_at_least_home_feed_minimum_score
      .cached_tagged_with_any(tag_names)
      .or(Article.featured.published.where("published_at > ?", 1.week.ago)
        .with_at_least_home_feed_minimum_score)
      .order("last_comment_at DESC")
      .limit(5)
      .pluck(:path, :title, :comments_count, :created_at)
  end
end
