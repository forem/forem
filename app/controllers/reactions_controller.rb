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
    result = ""
    if reaction
      current_user.touch
      reaction.destroy
      Moderator::SinkArticles.call(reaction.reactable_id) if vomit_reaction_on_user?(reaction)
      Notification.send_reaction_notification_without_delay(reaction, reaction_user(reaction))
      Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.organization) if organization_article?(reaction)
      result = "destroy"
    else
      create_params = {
        user_id: current_user.id,
        reactable_id: params[:reactable_id],
        reactable_type: params[:reactable_type],
        category: category
      }
      create_params[:status] = "confirmed" if current_user&.any_admin?
      reaction = Reaction.new(create_params)

      unless reaction.save
        render json: { error: reaction.errors.full_messages.join(", "), status: 422 }, status: :unprocessable_entity
        return
      end

      result = "create"
      Moderator::SinkArticles.call(reaction.reactable_id) if vomit_reaction_on_user?(reaction)
      Notification.send_reaction_notification(reaction, reaction_user(reaction))
      Notification.send_reaction_notification(reaction, reaction.reactable.organization) if organization_article?(reaction)
      if category == "readinglist" && current_user.experience_level
        RatingVote.create(article_id: reaction.reactable_id,
                          group: "experience_level",
                          user_id: current_user.id,
                          context: "readinglist_reaction",
                          rating: current_user.experience_level)
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

  def reaction_user(reaction)
    if reaction.reactable_type == "User"
      reaction.reactable
    else
      reaction.reactable.user
    end
  end

  def organization_article?(reaction)
    reaction.reactable_type == "Article" && reaction.reactable.organization.present?
  end

  def vomit_reaction_on_user?(reaction)
    reaction.reactable_type == "User" && reaction.category == "vomit"
  end
end
