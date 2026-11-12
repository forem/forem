module Users
  class Delete
    def self.call(user, &block)
      new(user).call(&block)
    end

    def initialize(user)
      @user = user
    end

    # Anything that must happen once the user is gone (and must not be lost if
    # it fails) belongs in the block: it runs in the same transaction as the
    # destroy, so if it raises the user is kept and a retry can do it all again.
    # Enqueue jobs from it rather than calling external services directly.
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

      User.transaction do
        destroy_user
        EdgeCache::PurgeByKeyWorker.perform_in(
          BustCacheBaseWorker::AFTER_COMMIT_DELAY, profile_cache_keys, profile_cache_bust_paths
        )
        yield if block_given?
      end

      Rails.cache.delete("user-destroy-token-#{user.id}")
    end

    private

    attr_reader :user

    def destroy_user
      # a savepoint, so the transaction survives a failed attempt
      User.transaction(requires_new: true) { user.destroy! }
    rescue ActiveRecord::InvalidForeignKey => e
      raise unless e.message.include?("ai_audits")

      AiAudit.where(affected_user_id: user.id).update_all(affected_user_id: nil)
      user.reload
      user.destroy!
    end

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
