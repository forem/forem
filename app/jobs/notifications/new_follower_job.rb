module Notifications
  class NewFollowerJob < ApplicationJob
    queue_as :send_new_follower_notification

    def perform(follow_data, is_read = false, service = Notifications::NewFollower::Send)
      service.call(follow_data, is_read)
    end
  end
end
