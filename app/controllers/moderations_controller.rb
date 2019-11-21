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
    @moderatable = Article.find_by(slug: params[:slug])
    @adjustments = TagAdjustment.where(article_id: @moderatable.id)
    @removed_adjustments = @adjustments.filter { |a| a.adjustment_type == "removal" }
    @added_adjustments = @adjustments.filter { |a| a.adjustment_type == "addition" }
    @already_adjusted_tags = @adjustments.map(&:tag_name).join(", ")
    @allowed_to_add = @moderatable.class.name == "Article" && (current_user.has_role?(:super_admin) || current_user.has_role?(:tag_moderator, :any))
    render template: "moderations/mod"
  end

  def comment
    authorize(User, :moderation_routes?)
    @moderatable = Comment.find(params[:id_code].to_i(26))
    render template: "moderations/mod"
  end
end
