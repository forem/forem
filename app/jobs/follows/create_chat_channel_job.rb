module Follows
  class CreateChatChannelJob < ApplicationJob
    queue_as :create_chat_channel_after_follow

    def perform(follow_id)
      follow = Follow.includes(:follower, :followable).find_by(id: follow_id, follower_type: "User", followable_type: "User")
      return unless follow&.followable&.following?(follow.follower)

      ChatChannel.create_with_users([follow.followable, follow.follower])
    end
  end
end
