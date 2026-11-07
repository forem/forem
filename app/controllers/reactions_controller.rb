class ReactionsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index], unless: -> { session_current_user_id }
  skip_before_action :verify_private_forem,
                     :remember_cookie_sync,
                     :forward_to_app_config_domain,
                     :redirect_custom_domain_non_profile_pages,
                     :determine_locale,
                     :set_request_signed_in_context,
                     only: [:index]
  before_action :authorize_for_reaction, :check_limit, only: [:create]
  after_action :verify_authorized

  NEGATIVE_CATEGORIES = %w[thumbsdown vomit].freeze
  MODERATION_CATEGORIES = %w[thumbsup thumbsdown vomit].freeze

  def index
    skip_authorization
    request.session_options[:skip] = true

    if params[:article_id]
      id = params[:article_id]

      reactions = reactions_by_user_id(session_current_user_id) if session_current_user_id
      reactions ||= Reaction.none

      result = { article_reaction_counts: Reaction.count_for_article(id) }
    else
      comment_rows = Comment
        .where(commentable_id: params[:commentable_id], commentable_type: params[:commentable_type])
        .pluck(:id, :public_reactions_count)

      reaction_counts = comment_rows.map do |cid, count|
        { id: cid, count: count }
      end

      reactions = if session_current_user_id && comment_rows.any?
                    comment_ids = comment_rows.map(&:first)
                    viewer = User.select(:id, :updated_at, :public_reactions_count).find_by(id: session_current_user_id)
                    viewer ? cached_user_public_comment_reactions(viewer, comment_ids) : Reaction.none
                  else
                    Reaction.none
                  end

      result = { public_reaction_counts: reaction_counts }
    end

    render json: {
      current_user: { id: session_current_user_id },
      reactions: reactions
    }.merge(result).to_json

    return if session_current_user_id

    surrogate_key = reactions_surrogate_key
    set_surrogate_key_header(surrogate_key) if surrogate_key
    set_cache_control_headers(2.weeks.to_i, stale_if_error: 1.day.to_i)
  end

  # @todo Extract this method into a service class (or classes)
  def create
    remove_count_cache_key
    remove_reaction_counts_cache_key

    result = ReactionHandler.toggle(params, current_user: current_user)

    if result.success?
      send_algolia_insight if result.action == "create"
      render json: { result: result.action, category: result.category }
    else
      render json: { error: result.errors_as_sentence, status: 422 }, status: :unprocessable_entity
    end
  end

  def cached_user_public_comment_reactions(user, comment_ids)
    cache = Rails.cache.fetch("#{user.cache_key}/public-comment-reactions-#{user.public_reactions_count}",
                              expires_in: 24.hours) do
      user.reactions.public_category.where(reactable_type: "Comment").each_with_object({}) do |r, h|
        h[r.reactable_id] = r.attributes
      end
    end
    cache.slice(*comment_ids).values
  end

  private

  def reactions_surrogate_key
    if params[:article_id]
      article_id = Article.where(id: params[:article_id]).pick(:id)
      return Reaction.surrogate_key_for_article(article_id) if article_id
    else
      commentable = commentable_for_reactions
      return Reaction.surrogate_key_for_commentable(commentable) if commentable
    end
  end

  def commentable_for_reactions
    return unless params[:commentable_id] && params[:commentable_type]
    return unless params[:commentable_type].in?(Comment::COMMENTABLE_TYPES)

    # Only the id is needed for the surrogate key; avoid hydrating large text columns.
    params[:commentable_type].constantize.select(:id).find_by(id: params[:commentable_id])
  end

  def check_limit
    rate_limit!(:reaction_creation)
  end

  def authorize_for_reaction
    # A present assumption is that who can give a reaction is not dependent on the reactable;
    # however it is dependent on the category of the reaction.
    policy_query = ReactionPolicy.policy_query_for(category: params[:category])
    authorize(Reaction, policy_query)
  end

  def reactions_by_user_id(user_id = session_current_user_id)
    id = params[:article_id]

    # Single lookup on the (user_id, reactable_id, reactable_type, category) unique index,
    # keeping public reactions ahead of the readinglist one as before.
    readinglist, public_reactions = Reaction.where(
      reactable_id: id,
      reactable_type: "Article",
      user_id: user_id,
      category: Reaction.public_reaction_types + ["readinglist"],
    ).partition { |reaction| reaction.category == "readinglist" }

    public_reactions + readinglist
  end

  # TODO: should this move to toggle service? refactor?
  def remove_count_cache_key
    return unless params[:reactable_type] == "Article"

    Rails.cache.delete "count_for_reactable-Article-#{params[:reactable_id]}"
    Rails.cache.delete "reaction_counts_for_reactable-Article-#{params[:reactable_id]}"
  end

  def remove_reaction_counts_cache_key
    return unless params[:reactable_type] && params[:reactable_id]

    Rails.cache.delete "reaction_counts_for_reactable-#{params[:reactable_type]}-#{params[:reactable_id]}"
  end

  def send_algolia_insight
    return unless session_current_user_id &&
      params[:reactable_type] == "Article" &&
      Settings::General.algolia_application_id.present? &&
      Settings::General.algolia_api_key.present?

    AlgoliaInsightsService.new.track_event(
      "conversion",
      "Reaction Created",
      session_current_user_id,
      params[:reactable_id].to_i,
      "Article_#{Rails.env}",
      Time.current.to_i * 1000,
      nil,
      nil
    )
  end
end
