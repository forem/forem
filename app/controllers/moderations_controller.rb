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

    # Use the optimized service to fetch articles
    @articles = Moderations::ArticleFetcherService.new(
      user: current_user,
      feed: @feed,
      members: @members,
      tag: params[:tag]
    ).call

    # Cache tag-related queries
    if params[:tag].present?
      @tag = Rails.cache.fetch("moderations_tag_#{params[:tag]}", expires_in: 1.hour) do
        Tag.find_by(name: params[:tag]) || not_found
      end
    end

    # Cache user tag queries
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
