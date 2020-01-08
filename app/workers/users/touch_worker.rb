module Users
  class TouchWorker
    include Sidekiq::Worker
    sidekiq_options queue: :touch_user

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      user.touch
    end
  end
end
