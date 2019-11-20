module Reactions
  class TouchUsersJob < ApplicationJob
    queue_as :touch_users

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction

      reaction_user = reaction&.user
      reaction_user&.touch(:updated_at, :last_reaction_at)
    end
  end
end
