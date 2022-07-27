class ModerationsController < ApplicationController
  after_action :verify_authorized

  JSON_OPTIONS = {
    only: %i[id title published_at cached_tag_list path],
    include: {
      user: { only: %i[username name path articles_count id] }
    }
  }.freeze

  def index
    skip_authorization
    return unless current_user&.trusted?

    articles = Article.published
      .order(published_at: :desc).limit(70)
    articles = articles.cached_tagged_with(params[:tag]) if params[:tag].present?
    if params[:state] == "new-authors"
      articles = articles.where("nth_published_by_author > 0 AND nth_published_by_author < 4 AND published_at > ?",
                                7.days.ago)
    end
    @articles = articles.includes(:user).to_json(JSON_OPTIONS)
    @tag = Tag.find_by(name: params[:tag]) || not_found if params[:tag].present?
    @current_user_tags = current_user.moderator_for_tags
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
    render template: "moderations/actions_panel"
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
