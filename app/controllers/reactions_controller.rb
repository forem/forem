class ReactionsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index], unless: -> { current_user }
  after_action :verify_authorized

  def index
    skip_authorization

    if params[:article_id]
      id = params[:article_id]

      reactions = if session_current_user_id
                    Reaction.positive.
                      where(
                        reactable_id: id,
                        reactable_type: "Article",
                        user_id: session_current_user_id,
                      )
                  else
                    Reaction.none
                  end

      result = { article_reaction_counts: Reaction.count_for_article(id) }
    else
      comments = Comment.
        where(commentable_id: params[:commentable_id], commentable_type: params[:commentable_type]).
        select(%i[id positive_reactions_count])

      reaction_counts = comments.map do |comment|
        { id: comment.id, count: comment.positive_reactions_count }
      end

      reactions = if session_current_user_id
                    comment_ids = reaction_counts.map { |rc| rc[:id] }
                    cached_user_positive_reactions(current_user).where(reactable_id: comment_ids)
                  else
                    Reaction.none
                  end

      result = { positive_reaction_counts: reaction_counts }
    end

    render json: {
      current_user: { id: session_current_user_id },
      reactions: reactions
    }.merge(result).to_json

    set_surrogate_key_header params.to_s unless session_current_user_id
  end

  def create
    authorize Reaction

    Rails.cache.delete "count_for_reactable-#{params[:reactable_type]}-#{params[:reactable_id]}"

    category = params[:category] || "like"
    reaction = Reaction.where(
      user_id: current_user.id,
      reactable_id: params[:reactable_id],
      reactable_type: params[:reactable_type],
      category: category,
    ).first

    # if the reaction already exists, destroy it
    if reaction
      result = destroy_reaction(reaction)

      if reaction.negative? && current_user.auditable?
        updated_params = params.dup
        updated_params[:action] = "destroy"
        Audit::Logger.log(:moderator, current_user, updated_params)
      end
    else
      reaction = build_reaction(category)

      if reaction.save
        Moderator::SinkArticles.call(reaction.reactable_id) if reaction.vomit_on_user?

        Notification.send_reaction_notification(reaction, reaction.target_user)
        Notification.send_reaction_notification(reaction, reaction.reactable.organization) if reaction.reaction_on_organization_article?

        result = "create"

        if category == "readinglist" && current_user.experience_level
          rate_article(reaction)
        end

        if reaction.negative? && current_user.auditable?
          Audit::Logger.log(:moderator, current_user, params.dup)
        end
      else
        render json: { error: reaction.errors.full_messages.join(", "), status: 422 }, status: :unprocessable_entity
        return
      end
    end
    render json: { result: result, category: category }
  end

  def cached_user_positive_reactions(user)
    Rails.cache.fetch("cached_user_reactions-#{user.id}-#{user.updated_at}", expires_in: 24.hours) do
      user.reactions.positive
    end
  end

  private

  def build_reaction(category)
    create_params = {
      user_id: current_user.id,
      reactable_id: params[:reactable_id],
      reactable_type: params[:reactable_type],
      category: category
    }
    create_params[:status] = "confirmed" if current_user&.any_admin?
    Reaction.new(create_params)
  end

  def destroy_reaction(reaction)
    current_user.touch
    reaction.destroy
    Moderator::SinkArticles.call(reaction.reactable_id) if reaction.vomit_on_user?
    Notification.send_reaction_notification_without_delay(reaction, reaction.target_user)
    Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.organization) if reaction.reaction_on_organization_article?
    "destroy"
  end

  def rate_article(reaction)
    RatingVote.create(article_id: reaction.reactable_id,
                      group: "experience_level",
                      user_id: current_user.id,
                      context: "readinglist_reaction",
                      rating: current_user.experience_level)
  end
end
