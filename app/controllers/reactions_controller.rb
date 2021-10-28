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

  def create
    remove_count_cache_key

    if params[:reactable_type] == "Article" && params[:category].in?(MODERATION_CATEGORIES)
      clear_moderator_reactions(
        params[:reactable_id],
        params[:reactable_type],
        current_user,
        params[:category],
      )
    end

    category = params[:category] || "like"

    reaction = Reaction.where(
      user_id: current_user.id,
      reactable_id: params[:reactable_id],
      reactable_type: params[:reactable_type],
      category: category,
    ).first

    # if the reaction already exists, destroy it
    if reaction
      result = handle_existing_reaction(reaction)
    else
      reaction = build_reaction(category)

      if reaction.save
        rate_limiter.track_limit_by_action(:reaction_creation)
        Moderator::SinkArticles.call(reaction.reactable_id) if reaction.vomit_on_user?

        Notification.send_reaction_notification(reaction, reaction.target_user)
        if reaction.reaction_on_organization_article?
          Notification.send_reaction_notification(reaction,
                                                  reaction.reactable.organization)
        end

        result = "create"

        if category == "readinglist" && current_user.setting.experience_level
          rate_article(reaction)
        end

        if current_user.auditable?
          Audit::Logger.log(:moderator, current_user, params.dup)
        end
      else
        render json: { error: reaction.errors_as_sentence, status: 422 }, status: :unprocessable_entity
        return
      end
    end
    render json: { result: result, category: category }
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

  def build_reaction(category)
    create_params = {
      user_id: current_user.id,
      reactable_id: params[:reactable_id],
      reactable_type: params[:reactable_type],
      category: category
    }
    if current_user&.any_admin? && NEGATIVE_CATEGORIES.include?(category)
      create_params[:status] = "confirmed"
    end
    Reaction.new(create_params)
  end

  def destroy_reaction(reaction)
    reaction.destroy
    Moderator::SinkArticles.call(reaction.reactable_id) if reaction.vomit_on_user?
    Notification.send_reaction_notification_without_delay(reaction, reaction.target_user)
    if reaction.reaction_on_organization_article?
      Notification.send_reaction_notification_without_delay(reaction,
                                                            reaction.reactable.organization)
    end
    "destroy"
  end

  def rate_article(reaction)
    user_experience_level = current_user.setting.experience_level
    return unless user_experience_level

    RatingVote.create(article_id: reaction.reactable_id,
                      group: "experience_level",
                      user_id: current_user.id,
                      context: "readinglist_reaction",
                      rating: user_experience_level)
  end

  def clear_moderator_reactions(id, type, mod, category)
    reactions = if category == "thumbsup"
                  Reaction.where(reactable_id: id, reactable_type: type, user: mod, category: NEGATIVE_CATEGORIES)
                elsif category.in?(NEGATIVE_CATEGORIES)
                  Reaction.where(reactable_id: id, reactable_type: type, user: mod, category: "thumbsup")
                end

    return if reactions.blank?

    reactions.find_each { |reaction| destroy_reaction(reaction) }
  end

  def handle_existing_reaction(reaction)
    result = destroy_reaction(reaction)

    if reaction.negative? && current_user.auditable?
      updated_params = params.dup
      updated_params[:action] = "destroy"
      Audit::Logger.log(:moderator, current_user, updated_params)
    end

    result
  end

  def check_limit
    rate_limit!(:reaction_creation)
  end

  def authorize_for_reaction
    authorize Reaction
  end

  def remove_count_cache_key
    return unless params[:reactable_type] == "Article"

    Rails.cache.delete "count_for_reactable-Article-#{params[:reactable_id]}"
  end
end
