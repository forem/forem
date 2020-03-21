class Internal::ModActionsController < Internal::ApplicationController
  layout "internal"

  NEGATIVE_REACTION_CATEGORIES = %i[vomit thumbsdown].freeze

  def index
    community_mod_ids = User.with_role(:trusted).pluck(:id)
    tag_mod_ids = User.with_role(:tag_moderator).pluck(:id)
    mod_ids = community_mod_ids | tag_mod_ids
    @q = Reaction.
      includes(:user,
               :reactable).
      where("user_id IN (?) AND category IN (?)", mod_ids, NEGATIVE_REACTION_CATEGORIES).
      order("reactions.created_at DESC").
      ransack(params[:q])
    @mod_actions = @q.result.page(params[:page] || 1).per(5)
  end
end
