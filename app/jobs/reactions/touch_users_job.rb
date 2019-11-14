module Reactions
  class TouchUsersJob < ApplicationJob
    queue_as :touch_users

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction

      reaction_user = reaction&.user
      reaction_user&.touch(:updated_at, :last_reaction_at)
      reaction_user&.update_columns(
        trailing_7_day_reactions_count: reaction_user&.reactions&.where("created_at > ?", 7.days.ago)&.size || 0,
        trailing_28_day_reactions_count: reaction_user&.reactions&.where("created_at > ?", 28.days.ago)&.size || 0,
      )
    end
  end
end
