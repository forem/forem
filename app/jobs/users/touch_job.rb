module Users
  class TouchJob < ApplicationJob
    queue_as :touch_user

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      user.touch
    end
  end
end
