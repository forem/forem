module Users
  class DeleteJob < ApplicationJob
    queue_as :users_delete

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      Users::Delete.call(user)
    end
  end
end
