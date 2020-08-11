module Users
  class DeleteWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(user_id, admin_delete = false) # rubocop:disable Style/OptionalBooleanParameter
      user = User.find_by(id: user_id)
      return unless user

      Users::Delete.call(user)
      return if admin_delete || user.email.blank?

      NotifyMailer.with(user: user).account_deleted_email.deliver_now
    rescue StandardError => e
      DatadogStatsClient.count("users.delete", 1, tags: ["action:failed", "user_id:#{user.id}"])
      Honeybadger.context({ user_id: user.id })
      Honeybadger.notify(e)
    end
  end
end
