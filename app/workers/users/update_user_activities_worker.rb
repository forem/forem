module Users
  class UpdateUserActivitiesWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      activity = UserActivity.find_or_initialize_by(user_id: user.id)
      activity.set_activity
      activity.save!
    end
  end
end