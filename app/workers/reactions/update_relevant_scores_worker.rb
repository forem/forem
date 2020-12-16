module Reactions
  class UpdateRelevantScoresWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      return unless reaction&.reactable

      reaction.reactable.touch_by_reaction if reaction.reactable.respond_to?(:touch_by_reaction)
      reaction.reactable.sync_reactions_count if rand(6) == 1 && reaction.reactable.respond_to?(:sync_reactions_count)
      return unless reaction.reactable_type == "Article" && Reaction::PUBLIC_CATEGORIES.include?(reaction.category)

      Follows::UpdatePointsWorker.perform_async(reaction.reactable_id, reaction.user_id)
    end
  end
end
