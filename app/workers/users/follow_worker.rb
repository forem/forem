module Users
  class FollowWorker
    include Sidekiq::Worker
    sidekiq_options queue: :high_priority, retry: 10

    def perform(user_id, followable_id, followable_type)
      return unless %w[Tag Organization User].include?(followable_type)

      user = User.find_by(id: user_id)
      followable = followable_type.constantize.find_by(id: followable_id)

      return unless user && followable

      user.follow(followable)
    end
  end
end
