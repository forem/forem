module Reactions
  class ReactionCreateJob < ApplicationJob
    queue_as :reaction_create

    def perform(user_id:, reactable_id:, reactable_type:, category:)
      Reaction.create(
        user_id: user_id,
        reactable_id: reactable_id,
        reactable_type: reactable_type,
        category: category,
      )
    end
  end
end
