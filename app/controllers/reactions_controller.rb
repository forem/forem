class ReactionsController < ApplicationController
  before_action :set_cache_control_headers,
                only: [:index],
                unless: -> { session_or_remembered_user_id || cookies[:remember_user_token].present? }
  skip_before_action :remember_cookie_sync,
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
    user_id = session_or_remembered_user_id
    request.session_options[:skip] = true unless remembered_user_restored?

    reactions, result, has_reactions = if params[:article_id]
                                         article_reactions_payload(params[:article_id], user_id)
                                       else
                                         comment_reactions_payload(user_id)
                                       end

    render json: {
      current_user: { id: user_id },
      reactions: reactions
    }.merge(result).to_json

    return if user_id || cookies[:remember_user_token].present?

    surrogate_key = reactions_surrogate_key(has_reactions: has_reactions)
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

  def article_reactions_payload(article_id, user_id)
    reactions = user_id ? reactions_by_user_id(user_id) : Reaction.none
    counts = Reaction.count_for_article(article_id)
    has_reactions = counts.any? { |entry| entry[:count].to_i.positive? }
    [reactions, { article_reaction_counts: counts }, has_reactions]
  end

  def comment_reactions_payload(user_id)
    comment_rows = Comment
      .where(commentable_id: params[:commentable_id], commentable_type: params[:commentable_type])
      .pluck(:id, :public_reactions_count)
    reaction_counts = comment_rows.map { |cid, count| { id: cid, count: count } }
    reactions = if user_id && comment_rows.any?
                  viewer = User.select(:id, :updated_at, :public_reactions_count).find_by(id: user_id)
                  viewer ? cached_user_public_comment_reactions(viewer, comment_rows.map(&:first)) : Reaction.none
                else
                  Reaction.none
                end
    [reactions, { public_reaction_counts: reaction_counts }, comment_rows.any?]
  end

  def reactions_surrogate_key(has_reactions: false)
    if params[:article_id]
      article_id = positive_id_param(params[:article_id]) if has_reactions
      article_id ||= Article.where(id: params[:article_id]).pick(:id)
      Reaction.surrogate_key_for_article(article_id) if article_id
    else
      commentable = commentable_for_reactions(has_reactions: has_reactions)
      Reaction.surrogate_key_for_commentable(commentable) if commentable
    end
  end

  def commentable_for_reactions(has_reactions: false)
    return unless params[:commentable_id] && params[:commentable_type]
    return unless params[:commentable_type].in?(Comment::COMMENTABLE_TYPES)

    commentable_klass = params[:commentable_type].constantize
    if has_reactions && (commentable_id = positive_id_param(params[:commentable_id]))
      return commentable_klass.new(id: commentable_id)
    end

    # Only the id is needed for the surrogate key; avoid hydrating large text columns.
    commentable_klass.select(:id).find_by(id: params[:commentable_id])
  end

  def positive_id_param(raw_id)
    id = Integer(raw_id.to_s, 10, exception: false)
    id if id&.positive?
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

    AlgoliaInsights::TrackEventWorker.perform_async(
      "conversion",
      "Reaction Created",
      session_current_user_id,
      params[:reactable_id].to_i,
      "Article_#{Rails.env}",
      Time.current.to_i * 1000,
      nil,
      nil,
      RequestStore.store[:subforem_id],
    )
  end
end
