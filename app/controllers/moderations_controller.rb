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
    return unless current_user&.trusted

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
    @community_mod_channel = current_user.chat_channels.find_by("channel_name LIKE ?", "Community Mods: Team%")
  end

  def article
    load_article
    render template: "moderations/mod"
  end

  def comment
    authorize(User, :moderation_routes?)
    @moderatable = Comment.find(params[:id_code].to_i(26))
    render template: "moderations/mod"
  end

  def actions_panel
    load_article
    tag_mod_tag_ids = @tag_moderator_tags.ids
    has_room_for_tags = @moderatable.tag_list.size < 4
    has_no_relevant_adjustments = @adjustments.pluck(:tag_id).intersection(tag_mod_tag_ids).size.zero?
    can_be_adjusted = @moderatable.tags.ids.intersection(tag_mod_tag_ids).size.positive?

    @should_show_adjust_tags = tag_mod_tag_ids.size.positive? &&
      ((has_room_for_tags && has_no_relevant_adjustments) ||
        (!has_room_for_tags && has_no_relevant_adjustments && can_be_adjusted))

    render template: "moderations/actions_panel"
  end

  private

  def load_article
    authorize(User, :moderation_routes?)

    @tag_adjustment = TagAdjustment.new
    @moderatable = Article.find_by(slug: params[:slug])
    not_found unless @moderatable
    @tag_moderator_tags = Tag.with_role(:tag_moderator, current_user)
    @adjustments = TagAdjustment.where(article_id: @moderatable.id)
    @already_adjusted_tags = @adjustments.map(&:tag_name).join(", ")
    @allowed_to_adjust = @moderatable.instance_of?(Article) && (
      current_user.has_role?(:super_admin) || @tag_moderator_tags.any?)
    @hidden_comments = @moderatable.comments.where(hidden_by_commentable_user: true)
  end
end
