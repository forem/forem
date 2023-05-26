module Reactions
  class UpdateReactableWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(reactable_id, reactable_type)
      return unless %w[Article Comment User].include?(reactable_type)

      reactable = reactable_type.constantize.find_by(id: reactable_id)
      return unless reactable

      reactable.touch_by_reaction if reactable.respond_to?(:touch_by_reaction)
      reactable.calculate_score if reactable_type == "User"

      return unless reactable.respond_to?(:sync_reactions_count)

      ThrottledCall.perform(:sync_reactions_count, throttle_for: 15.minutes) do
        reactable.sync_reactions_count
      end
    end
  end
end
