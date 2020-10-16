module Users
  class DeleteWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(user_id, admin_delete = false) # rubocop:disable Style/OptionalBooleanParameter
      user = User.find_by(id: user_id)
      return unless user

      Users::Delete.call(user)
      # notify admins internally that they need to delete gdpr data
      Users::GdprDeleteRequest.create(user_id: user.id, email: user.email, username: user.username)

      return if admin_delete || user.email.blank?

      # at this point the user object is already destroyed on the DB,
      # thus we pass the data we need to render to deliver the email, not the
      # whole object
      NotifyMailer.with(name: user.name, email: user.email).account_deleted_email.deliver_now

      # notify admins about self-delete
      Slack::Messengers::UserDeleted.call(name: user.name, user_url: URL.user(user))
    rescue StandardError => e
      DatadogStatsClient.count("users.delete", 1, tags: ["action:failed", "user_id:#{user.id}"])
      Honeybadger.context({ user_id: user.id })
      Honeybadger.notify(e)
    end
  end
end
