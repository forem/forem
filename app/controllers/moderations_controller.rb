class ModerationsController < ApplicationController
  after_action :verify_authorized

  SCORE_MIN = -10
  SCORE_MAX = 5

  JSON_OPTIONS = {
    only: %i[id title published_at cached_tag_list path nth_published_by_author],
    include: {
      user: { only: %i[username name path articles_count id] }
    }
  }.freeze

  def index
    skip_authorization
    return unless current_user&.trusted?

    @feed = params[:state] == "latest" ? "latest" : "inbox"
    @members = params[:members].in?(%w[new not_new]) ? params[:members] : "all"

    # exclude articles from users that have suspended or spam role
    role_ids = Role.where(name: %i[spam suspended]).ids
    articles = Article.published.from_subforem
      .where("NOT EXISTS (SELECT 1 FROM users_roles WHERE users_roles.user_id = articles.user_id AND
             role_id IN (?))", role_ids)
      .order(published_at: :desc).limit(70)

    articles = articles.cached_tagged_with(params[:tag]) if params[:tag].present?
    if @feed == "inbox"
      articles = articles
        .joins("LEFT OUTER JOIN reactions ON articles.id = reactions.reactable_id AND
               reactions.reactable_type = 'Article' AND reactions.user_id = #{current_user.id}")
        .where("articles.score >= ? AND articles.score <= ?", SCORE_MIN, SCORE_MAX)
        .where(reactions: { id: nil })
    end
    if @members == "new"
      articles = articles.where("nth_published_by_author > 0 AND nth_published_by_author < 4")
    elsif @members == "not_new"
      articles = articles.where("nth_published_by_author > 3")
    end
    @articles = articles.includes(:user).reject { |article| article.title == "[Boost]" }.to_json(JSON_OPTIONS)
    @tag = Tag.find_by(name: params[:tag]) || not_found if params[:tag].present?
    @current_user_tags = current_user.moderator_for_tags
    @current_user_following_tags = current_user.currently_following_tags.pluck(:name) - @current_user_tags
  end

  def article
    load_article
    render template: "moderations/mod"
  end

  def comment
    authorize(Comment, :moderate?)
    @moderatable = Comment.find(params[:id_code].to_i(26))

    render template: "moderations/mod"
  end

  def actions_panel
    load_article
    @author_flagged ||= Reaction.user_vomits.valid_or_confirmed.where(
      user_id: session_current_user_id,
      reactable_id: @moderatable.user_id,
    ).any?
    render template: "moderations/actions_panel", locals: { is_mod_center: params[:is_mod_center] }
  end

  private

  def load_article
    authorize(Article, :moderate?)

    @tag_adjustment = TagAdjustment.new
    @moderatable = Article.find_by(slug: params[:slug])
    not_found unless @moderatable
    @tag_moderator_tags = Tag.with_role(:tag_moderator, current_user)
    @allowed_to_adjust = @moderatable.instance_of?(Article) && (
      current_user.super_admin? || @tag_moderator_tags.any?)
    @hidden_comments = @moderatable.comments.where(hidden_by_commentable_user: true)
  end
end
