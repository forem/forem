module Users
  class SelfDeleteWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      Users::Delete.call(user)
      NotifyMailer.account_deleted_email(user).deliver
    rescue StandardError => e
      Rails.logger.error("Error while deleting user: #{e}")
    end
  end
end
