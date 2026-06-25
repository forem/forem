module Notifications
  class UpdateJsonDataForUserWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      Notifications::UpdateJsonDataForUser.call(user)
    end
  end
end
