module Users
  class FollowJob < ApplicationJob
    queue_as :users_follow

    def perform(user, followable)
      return unless user && followable

      user.follow(followable)
    end
  end
end
