module Reactions
  class CreateWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(user_id, reactable_id, reactable_type, category)
      return unless %w[Article Comment].include?(reactable_type)

      user = User.find_by(id: user_id)
      reactable = reactable_type.constantize.find_by(id: reactable_id)

      return unless user && reactable

      Reaction.create!(
        user: user,
        reactable: reactable,
        category: category,
      )
    end
  end
end
