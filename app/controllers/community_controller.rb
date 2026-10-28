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
    root_subforem_id = RequestStore.store[:root_subforem_id]
    @current_subforem = Subforem.find_by(id: subforem_id) if subforem_id
    @is_root_subforem = subforem_id.present? && subforem_id == root_subforem_id
    
    if @is_root_subforem
      # For root subforem: Show discoverable subforems instead of tags
      @subforems = Subforem
        .where(discoverable: true)
        .where.not(id: root_subforem_id)
        .order(hotness_score: :desc)
        .limit(12)
    else
      # For regular subforem: Show top tags by hotness
      @tags = Tag.from_subforem.direct.includes(:badge).order(hotness_score: :desc).limit(12)
    end
    
    # Get top recent authors ranked by community engagement rather than raw post volume.
    # Excludes feed-imported articles (RSS bots) and spam/suspended accounts.
    exclude_ids = [Settings::General.mascot_user_id, Settings::Community.staff_user_id].compact
    @top_authors = User
      .registered
      .where("users.score >= ?", 0)
      .where.not(
        UserRole.joins(:role)
          .where("users_roles.user_id = users.id")
          .where(roles: { name: %w[suspended spam], resource_type: nil, resource_id: nil })
          .select(1)
          .arel.exists,
      )
      .joins(:articles)
      .merge(
        Article.from_subforem
          .published
          .where(published_from_feed: false)
          .where("published_at > ?", 30.days.ago)
          .where("articles.score >= ?", 0),
      )
      .then { |scope| exclude_ids.any? ? scope.where.not(id: exclude_ids) : scope }
      .select(
        "users.*",
        "COUNT(articles.id) as recent_articles_count",
        "SUM(articles.public_reactions_count) as total_reactions",
        "SUM(articles.score) as total_score",
      )
      .group("users.id")
      .order("total_reactions DESC, total_score DESC, recent_articles_count DESC")
      .limit(8)
    
    # Get top recent videos
    @recent_videos = Article
      .with_video
      .from_subforem
      .includes(:user)
      .order(published_at: :desc)
      .limit(8)
    
    # Get key pages for this subforem
    @key_pages = Page.where(subforem_id: RequestStore.store[:subforem_id]).where(is_top_level_path: true).limit(6)
    
    # Get welcome article if it exists
    @welcome_article = Article.cached_admin_published_with("welcome", subforem_id: RequestStore.store[:subforem_id]) ||
                       Article.cached_admin_published_with("welcome")
    
    set_surrogate_key_header "community_hub"
  end
end

