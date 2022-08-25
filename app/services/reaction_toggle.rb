class ReactionToggle
  class Result
    attr_accessor :action, :category, :reaction

    delegate :errors_as_sentence, to: :reaction

    def initialize(reaction: nil, action: nil, category: nil)
      @reaction = reaction
      @category = category
      @action = action
    end

    def success?
      reaction.errors.none?
    end
  end

  def self.toggle(params, current_user:)
    new(params, current_user: current_user).toggle
  end

  def initialize(params, current_user:)
    @current_user = current_user

    @params = params
    @reactable_id = params[:reactable_id]
    @reactable_type = params[:reactable_type]
    @category = params[:category] || "like"
  end

  attr_reader :reactable_id, :reactable_type, :category, :params, :current_user

  delegate :rate_limiter, to: :current_user

  def toggle
    if reactable_type == "Article" && category.in?(Reaction::PRIVILEGED_CATEGORIES)
      destroy_contradictory_mod_reactions
    end

    @existing_reaction ||= existing_reaction
    if @existing_reaction
      handle_existing_reaction
    else
      create_new_reaction
    end
  end

  private

  def destroy_contradictory_mod_reactions
    reactions = Reaction.contradictory_mod_reactions(
      category: category,
      reactable_id: reactable_id,
      reactable_type: reactable_type,
      user: current_user,
    )
    return if reactions.blank?

    reactions.find_each { |reaction| destroy_reaction(reaction) }
  end

  def destroy_reaction(reaction)
    reaction.destroy
    sink_articles(reaction)
    send_notifications_without_delay(reaction)
  end

  def existing_reaction
    Reaction.where(
      user_id: current_user.id,
      reactable_id: reactable_id,
      reactable_type: reactable_type,
      category: category,
    ).first
  end

  def handle_existing_reaction
    return unless @existing_reaction

    destroy_reaction(@existing_reaction)
    log_audit(@existing_reaction)
    result(@existing_reaction, "destroy")
  end

  def create_new_reaction
    reaction = build_reaction(category)
    result = result(reaction, nil)

    if reaction.save
      rate_limit_reaction_creation
      sink_articles(reaction)
      send_notifications(reaction)
    end

    result.action = "create"

    if category == "readinglist" && current_user.setting.experience_level
      rate_article(reaction)
    end

    if current_user.auditable?
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    result
  end

  def build_reaction(category)
    create_params = {
      user_id: current_user.id,
      reactable_id: reactable_id,
      reactable_type: reactable_type,
      category: category
    }
    if (current_user&.any_admin? || current_user&.super_moderator?) &&
        Reaction::NEGATIVE_PRIVILEGED_CATEGORIES.include?(category)
      create_params[:status] = "confirmed"
    end
    Reaction.new(create_params)
  end

  def log_audit(reaction)
    return unless reaction.negative? && current_user.auditable?

    updated_params = params.dup
    updated_params[:action] = "destroy"
    Audit::Logger.log(:moderator, current_user, updated_params)
  end

  def result(reaction, action)
    if action
      Result.new category: category, reaction: reaction, action: action
    else
      Result.new category: category, reaction: reaction
    end
  end

  def rate_limit_reaction_creation
    rate_limiter.track_limit_by_action(:reaction_creation)
  end

  def sink_articles(reaction)
    Moderator::SinkArticles.call(reaction.reactable_id) if reaction.vomit_on_user?
  end

  def send_notifications(reaction)
    Notification.send_reaction_notification(reaction, reaction.target_user)
    return unless reaction.reaction_on_organization_article?

    Notification.send_reaction_notification(reaction, reaction.reactable.organization)
  end

  def send_notifications_without_delay(reaction)
    Notification.send_reaction_notification_without_delay(reaction, reaction.target_user)
    return unless reaction.reaction_on_organization_article?

    Notification.send_reaction_notification_without_delay(reaction, reaction.reactable.organization)
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
end
