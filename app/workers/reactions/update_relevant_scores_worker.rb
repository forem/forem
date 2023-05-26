module Reactions
  class UpdateRelevantScoresWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction

      Reactions::UpdateReactableWorker.perform_async(reaction.reactable_id, reaction.reactable_type)

      return unless reaction.reactable_type == "Article" && reaction.visible_to_public?

      Follows::UpdatePointsWorker.perform_async(reaction.reactable_id, reaction.user_id)
    end
  end
end
