class ModerationsController < ApplicationController
  after_action :verify_authorized

  def index
    skip_authorization
    return unless current_user&.trusted

    @articles = Article.published.
      where("score > -5 AND score < 5").
      order("published_at DESC").limit(70)
    @articles = @articles.cached_tagged_with(params[:tag]) if params[:tag].present?
    @articles = @articles.where("nth_published_by_author > 0 AND nth_published_by_author < 4 AND published_at > ?", 7.days.ago) if params[:state] == "new-authors"
    @articles = @articles.decorate
    @tag = Tag.find_by(name: params[:tag])
    define_countables
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

  private

  def define_countables
    if @tag
      @tag_counts = @tag.sortable_counts.pluck(:slug, :number)
      @article_size = select_from_plucked_array(@tag_counts, "published_articles_this_7_days").to_i
      @comment_size = select_from_plucked_array(@tag_counts, "comments_this_7_days").to_i
      @reaction_size = select_from_plucked_array(@tag_counts, "reactions_this_7_days").to_i
      @article_change = (select_from_plucked_array(@tag_counts, "published_articles_change_7_days") * 100.0 - 100).to_i
      @comment_change = (select_from_plucked_array(@tag_counts, "comments_change_7_days") * 100.0 - 100).to_i
      @reaction_change = (select_from_plucked_array(@tag_counts, "reactions_change_7_days") * 100.0 - 100).to_i
    else
      @article_size = Article.published.where("published_at > ?", 7.days.ago).size
      @comment_size = Comment.where("created_at > ?", 7.days.ago).size
      @reaction_size = Reaction.where("created_at > ?", 7.days.ago).size

      define_changes
    end
  end

  def select_from_plucked_array(array, slug)
    array.select { |item| item[0] == slug }.flatten.last.to_f
  end

  def define_changes
    prior_article_size = Article.published.where("published_at > ? AND published_at < ?", 14.days.ago, 7.days.ago).size.to_f
    prior_article_size = 0.5 if prior_article_size.zero?
    prior_comment_size = Comment.where("created_at > ? AND created_at < ?", 14.days.ago, 7.days.ago).size.to_f
    prior_comment_size = 0.5 if prior_comment_size.zero?
    prior_reaction_size = Reaction.where("created_at > ? AND created_at < ?", 14.days.ago, 7.days.ago).size.to_f
    prior_reaction_size = 0.5 if prior_reaction_size.zero?

    @article_change = (@article_size / prior_article_size * 100.0 - 100).to_i
    @comment_change = (@comment_size / prior_comment_size * 100.0 - 100).to_i
    @reaction_change = (@reaction_size / prior_reaction_size * 100.0 - 100).to_i
  end
end
