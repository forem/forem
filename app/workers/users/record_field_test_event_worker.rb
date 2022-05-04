module Users
  class RecordFieldTestEventWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform(user_id, goal)
      user = User.find_by(id: user_id)
      return unless user

      AbExperiment.register_conversions_for(user: user, goal: goal)
    end
  end
end
