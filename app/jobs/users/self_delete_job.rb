module Users
  class SelfDeleteJob < ApplicationJob
    queue_as :users_self_delete

    def perform(user_id, service = Users::Delete)
      user = User.find_by(id: user_id)
      return unless user

      service.call(user)
      NotifyMailer.account_deleted_email(user).deliver
    rescue StandardError => e
      Rails.logger.error("Error while deleting user: #{e}")
    end
  end
end
