module Users
  class DeleteJob < ApplicationJob
    queue_as :users_delete

    def perform(user_id, service = Users::Delete)
      user = User.find_by(id: user_id)
      return unless user

      service.call(user)
    end
  end
end
