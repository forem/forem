module Reactions
  class UpdateReactableJob < ApplicationJob
    queue_as :update_reactable

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      reaction.reactable.touch_by_reaction if reaction.reactable.respond_to?(:touch_by_reaction)
      reaction.reactable.sync_reactions_count if rand(6) == 1 && reaction.reactable.respond_to?(:sync_reactions_count)
    end
  end
end
