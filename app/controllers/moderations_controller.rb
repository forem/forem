class ModerationsController < ApplicationController
  after_action :verify_authorized

  def index
    skip_authorization
    return unless current_user&.trusted

    @articles = Article.published.
      where("rating_votes_count < 3").
      where("score > -5").
      order("hotness_score DESC").limit(50)
    @articles = @articles.cached_tagged_with(params[:tag]) if params[:tag].present?

    @rating_votes = RatingVote.where(article: @articles, user: current_user)
    @articles = @articles.decorate
  end

  def article
    authorize(User, :moderation_routes?)
    @tag_adjustment = TagAdjustment.new
    @moderatable = Article.find_by(slug: params[:slug])
    @tag_moderator_tags = Tag.with_role(:tag_moderator, current_user)
    @adjustments = TagAdjustment.where(article_id: @moderatable.id)
    @already_adjusted_tags = @adjustments.map(&:tag_name).join(", ")
    @allowed_to_adjust = @moderatable.class.name == "Article" && (current_user.has_role?(:super_admin) || @tag_moderator_tags.any?)
    render template: "moderations/mod"
  end

  def comment
    authorize(User, :moderation_routes?)
    @moderatable = Comment.find(params[:id_code].to_i(26))
    render template: "moderations/mod"
  end
end
