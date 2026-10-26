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

      # These run in the same transaction as the destroy, so if one fails the
      # user is kept and the retry does it all again instead of skipping it.
      Users::Delete.call(user) do
        if reason == "gdpr"
          # notify admins internally that they need to delete gdpr data (a
          # request needs an email, users without one never got a record)
          if user.email.present?
            GDPRDeleteRequest.create!(user_id: user.id, email: user.email, username: user.username)
          end
          # tell MLH Core so it can erase the DEV-derived data it holds (the user
          # object is destroyed, but its in-memory attributes still feed the payload)
          user.track!("user_gdpr_deleted")
        end

        # the user is destroyed by now, so the email gets the data it renders
        # rather than the whole object
        unless admin_delete || user.email.blank?
          Users::SendAccountDeletedEmailWorker.perform_async(user.name, user.email)
        end
      end
    rescue StandardError
      ForemStatsClient.count("users.delete", 1, tags: ["action:failed", "user_id:#{user_id}"])
      Honeybadger.context({ user_id: user_id })
      # Re-raise so Sidekiq retries: every deletion step is safe to re-run, so a
      # retry picks up where a failed (e.g. timed out) attempt left off.
      # Honeybadger reports the failure once retries are exhausted.
      raise
    end
  end
end
