class SidebarsController < ApplicationController
  layout false
  before_action :set_cache_control_headers, only: %i[show]

  def show
    get_latest_campaign_articles
    set_surrogate_key_header "home-sidebar"
  end

  private

  def get_latest_campaign_articles
    campaign_articles_scope = Article.tagged_with(Campaign.current.featured_tags, any: true)
      .where("published_at > ? AND score > ?", SiteConfig.campaign_articles_expiry_time.weeks.ago, 0)
      .order(hotness_score: :desc)

    requires_approval = Campaign.current.articles_require_approval?
    campaign_articles_scope = campaign_articles_scope.where(approved: true) if requires_approval

    @campaign_articles_count = campaign_articles_scope.count
    @latest_campaign_articles = campaign_articles_scope.limit(5).pluck(:path, :title, :comments_count, :created_at)
  end
end
