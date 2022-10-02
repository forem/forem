class ReactionsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index], unless: -> { current_user }
  before_action :authorize_for_reaction, :check_limit, only: [:create]
  after_action :verify_authorized

  NEGATIVE_CATEGORIES = %w[thumbsdown vomit].freeze
  MODERATION_CATEGORIES = %w[thumbsup thumbsdown vomit].freeze

  def index
    skip_authorization

    if params[:article_id]
      id = params[:article_id]

      reactions = if session_current_user_id
                    Reaction.public_category
                      .where(
                        reactable_id: id,
                        reactable_type: "Article",
                        user_id: session_current_user_id,
                      )
                  else
                    Reaction.none
                  end

      result = { article_reaction_counts: Reaction.count_for_article(id) }
    else
      comments = Comment
        .where(commentable_id: params[:commentable_id], commentable_type: params[:commentable_type])
        .select(%i[id public_reactions_count])

      reaction_counts = comments.map do |comment|
        { id: comment.id, count: comment.public_reactions_count }
      end

      reactions = if session_current_user_id
                    comment_ids = reaction_counts.pluck(:id) # rubocop:disable Rails/PluckId
                    cached_user_public_comment_reactions(current_user, comment_ids)
                  else
                    Reaction.none
                  end

      result = { public_reaction_counts: reaction_counts }
    end

    render json: {
      current_user: { id: session_current_user_id },
      reactions: reactions
    }.merge(result).to_json

    set_surrogate_key_header params.to_s unless session_current_user_id
  end

  # @todo Extract this method into a service class (or classes)
  def create
    remove_count_cache_key

    result = ReactionHandler.toggle(params, current_user: current_user)

    if result.success?
      render json: { result: result.action, category: result.category }
    else
      render json: { error: result.errors_as_sentence, status: 422 }, status: :unprocessable_entity
    end
  end

  def cached_user_public_comment_reactions(user, comment_ids)
    cache = Rails.cache.fetch("cached-user-#{user.id}-reaction-ids-#{user.public_reactions_count}",
                              expires_in: 24.hours) do
      user.reactions.public_category.where(reactable_type: "Comment").each_with_object({}) do |r, h|
        h[r.reactable_id] = r.attributes
      end
    end
    cache.slice(*comment_ids).values
  end

  private

  def check_limit
    rate_limit!(:reaction_creation)
  end

  def authorize_for_reaction
    # A present assumption is that who can give a reaction is not dependent on the reactable;
    # however it is dependent on the category of the reaction.
    policy_query = ReactionPolicy.policy_query_for(category: params[:category])
    authorize(Reaction, policy_query)
  end

  # TODO: should this move to toggle service? refactor?
  def remove_count_cache_key
    return unless params[:reactable_type] == "Article"

    Rails.cache.delete "count_for_reactable-Article-#{params[:reactable_id]}"
  end
end
