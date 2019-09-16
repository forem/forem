module Reactions
  class CreateJob < ApplicationJob
    queue_as :reaction_create

    def perform(user_id:, reactable_id:, reactable_type:, category:)
      user = User.find_by(id: user_id)
      reactable = reactable_type.constantize.find_by(id: reactable_id)

      return unless user && reactable

      Reaction.create(
        user_id: user.id,
        reactable_id: reactable.id,
        reactable_type: reactable_type,
        category: category,
      )
    end
  end
end
