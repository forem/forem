module Moderator
  class GhostifyUserWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(target_user_id, action_user_id)
      GhostifyUser.call(target_user_id: target_user_id, action_user_id: action_user_id)
    end
  end
end
