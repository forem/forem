module Users
  class Delete
    def self.call(...)
      new(...).call
    end

    def initialize(user)
      @user = user
    end

    def call
      # captured up front, the profile can only be purged once the user is gone
      profile_cache_keys = user.profile_cache_keys
      profile_cache_bust_paths = user.profile_cache_bust_paths

      delete_comments
      delete_articles
      delete_podcasts
      delete_user_activity
      cancel_stripe_subscriptions
      # Mailchimp removal happens in User's before_destroy callback
      Users::SuspendedUsername.create_from_user(user) if user.spam_or_suspended?

      begin
        user.destroy
      rescue ActiveRecord::InvalidForeignKey => e
        raise unless e.message.include?("ai_audits")

        AiAudit.where(affected_user_id: user.id).update_all(affected_user_id: nil)
        user.reload
        user.destroy
      end

      Rails.cache.delete("user-destroy-token-#{user.id}")
      EdgeCache::PurgeByKeyWorker.perform_async(profile_cache_keys, profile_cache_bust_paths)
    end

    private

    attr_reader :user

    def delete_user_activity
      DeleteActivity.call(user)
    end

    def delete_comments
      DeleteComments.call(user)
    end

    def delete_articles
      DeleteArticles.call(user)
    end

    def delete_podcasts
      DeletePodcasts.call(user)
    end

    def cancel_stripe_subscriptions
      CancelStripeSubscriptions.call(user)
    end
  end
end
