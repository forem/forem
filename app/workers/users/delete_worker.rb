module Users
  class DeleteWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    # reason distinguishes true GDPR erasures (the default) from deletions
    # that only remove the row, like merges — those must not leave a
    # gdpr-delete reminder or tell MLH Core to erase the person's data.
    def perform(user_id, admin_delete = false, reason = "gdpr") # rubocop:disable Style/OptionalBooleanParameter
      user = User.find_by(id: user_id)
      return unless user

      Users::Delete.call(user)
      if reason == "gdpr"
        # notify admins internally that they need to delete gdpr data
        GDPRDeleteRequest.create(user_id: user.id, email: user.email, username: user.username)
        # tell MLH Core so it can erase the DEV-derived data it holds (the user
        # object is destroyed, but its in-memory attributes still feed the payload)
        user.track!("user_gdpr_deleted")
      end

      return if admin_delete || user.email.blank?

      # at this point the user object is already destroyed on the DB,
      # thus we pass the data we need to render to deliver the email, not the
      # whole object
      NotifyMailer.with(name: user.name, email: user.email).account_deleted_email.deliver_now
    rescue StandardError => e
      ForemStatsClient.count("users.delete", 1, tags: ["action:failed", "user_id:#{user.id}"])
      Honeybadger.context({ user_id: user.id })
      Honeybadger.notify(e)
    end
  end
end
