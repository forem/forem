module Follows
  class TouchFollowerJob < ApplicationJob
    queue_as :touch_follower

    def perform(follow_id)
      follow = Follow.find_by(id: follow_id)
      return unless follow

      follow.follower.touch
      follow.follower.touch(:last_followed_at)
    end
  end
end
