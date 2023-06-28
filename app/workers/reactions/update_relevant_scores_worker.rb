module Reactions
  class UpdateRelevantScoresWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reaction_id)
      reaction = Reaction.find_by(id: reaction_id)
      reactable = reaction&.reactable
      return unless reactable

      reactable.touch_by_reaction if reactable.respond_to?(:touch_by_reaction)
      if reactable.respond_to?(:sync_reactions_count)
        ThrottledCall.perform(:sync_reactions_count, throttle_for: 15.minutes) do
          reactable.sync_reactions_count
        end
      end

      reactable.calculate_score if reaction.reactable_type == "User"

      return unless reaction.reactable_type == "Article" && reaction.visible_to_public?

      Follows::UpdatePointsWorker.perform_async(reaction.reactable_id, reaction.user_id)
    end
  end
end
