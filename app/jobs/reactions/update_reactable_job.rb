module Reactions
  class UpdateReactableJob < ApplicationJob
    queue_as :update_reactable

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      if reaction.reactable_type == "Article"
        reaction.reactable.async_score_calc
        reaction.reactable.index!
      elsif reaction.reactable_type == "Comment"
        reaction.reactable.save
      end

      # occasionally sync reactions count
      if rand(6) == 1 || reaction.reactable.positive_reactions_count.negative?
        reaction.reactable.update_column(:positive_reactions_count, reaction.reactable.reactions.where("points > ?", 0).size)
      end
    end
  end
end
