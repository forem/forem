class CommunityController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index]
  after_action :verify_authorized

  def index
    skip_authorization
    @community_index = true
    
    # Set cache expiration to 120 seconds
    expires_in 120.seconds, public: true
    
    # Get current subforem
    subforem_id = RequestStore.store[:subforem_id]
    @current_subforem = Subforem.find_by(id: subforem_id) if subforem_id
    
    # Get top tags by hotness
    @tags = Tag.from_subforem.direct.order(hotness_score: :desc).limit(12)
    
    # Get top recent authors (users with most recent published articles)
    @top_authors = User
      .joins(:articles)
      .merge(Article.from_subforem.published.where("published_at > ?", 30.days.ago))
      .select("users.*, COUNT(articles.id) as recent_articles_count, SUM(articles.score) as total_score")
      .group("users.id")
      .order("total_score DESC, recent_articles_count DESC")
      .limit(8)
    
    # Get top recent videos
    @recent_videos = Article
      .with_video
      .from_subforem
      .includes(:user)
      .select(:id, :video, :path, :title, :video_thumbnail_url, :user_id, :video_duration_in_seconds, :published_at)
      .order(published_at: :desc)
      .limit(8)
    
    # Get key pages for this subforem
    @key_pages = Page.from_subforem.where(is_top_level_path: true).limit(6)
    
    # Get welcome article if it exists
    @welcome_article = Article.from_subforem.admin_published_with("welcome").first ||
                       Article.admin_published_with("welcome").first
    
    set_surrogate_key_header "community_hub"
  end
end

