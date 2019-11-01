class ReactionsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index], unless: -> { current_user }
  after_action :verify_authorized

  def index
    skip_authorization
    if params[:article_id]
      id = params[:article_id]
      reactions = if efficient_current_user_id.present?
                    Reaction.where(reactable_id: id,
                                   reactable_type: "Article",
                                   user_id: efficient_current_user_id).
                      where("points > ?", 0)
                  else
                    []
                  end
      render json:
      {
        current_user: { id: efficient_current_user_id },
        article_reaction_counts: Reaction.count_for_article(id),
        reactions: reactions
      }.to_json
    else
      comments = Comment.where(
        commentable_id: params[:commentable_id],
        commentable_type: params[:commentable_type],
      ).select(%i[id positive_reactions_count])
      comment_ids = comments.map(&:id)
      reaction_counts = comments.map { |c| { id: c.id, count: c.positive_reactions_count } }
      reactions = current_user ? cached_user_positive_reactions(current_user).where(reactable_id: comment_ids) : []
      render json:
        {
          current_user: { id: current_user&.id },
          positive_reaction_counts: reaction_counts,
          reactions: reactions
        }.to_json
    end
    set_surrogate_key_header params.to_s unless current_user
  end

  def create
    authorize Reaction
    RedisRailsCache.delete "count_for_reactable-#{params[:reactable_type]}-#{params[:reactable_id]}"
    category = params[:category] || "like"
    reaction = Reaction.where(
      user_id: current_user.id,
      reactable_id: params[:reactable_id],
      reactable_type: params[:reactable_type],
      category: category,
    ).first
    if reaction
      current_user.touch
      reaction.destroy
      Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.user)
      Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.organization) if organization_article?(reaction)
      @result = "destroy"
    else
      reaction = Reaction.create!(
        user_id: current_user.id,
        reactable_id: params[:reactable_id],
        reactable_type: params[:reactable_type],
        category: category,
      )
      @result = "create"
      Notification.send_reaction_notification(reaction, reaction.reactable.user)
      Notification.send_reaction_notification(reaction, reaction.reactable.organization) if organization_article?(reaction)
    end
    render json: { result: @result, category: category }
  end

  def cached_user_positive_reactions(user)
    Rails.cache.fetch("cached_user_reactions-#{user.id}-#{user.updated_at}", expires_in: 24.hours) do
      Reaction.where(user_id: user.id).
        where("points > ?", 0)
    end
  end

  private

  def organization_article?(reaction)
    reaction.reactable_type == "Article" && reaction.reactable.organization_id
  end
end
