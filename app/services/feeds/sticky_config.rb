module Feeds
  # Selects a configuration for a first-page home feed, including preloads.
  # Only an authenticated visibility acknowledgement can earn return credit.
  class StickyConfig
    def initialize(user:, subforem_id: RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id])
      @user = user
      @subforem_id = subforem_id
    end

    def select
      hours = Settings::UserExperience.feed_config_sticky_hours
      percentage = Settings::UserExperience.feed_config_sticky_percentage
      return select_random_config unless hours.positive? && rand(100) < percentage

      @assignment = FeedConfigAssignment.find_or_create_by!(user: @user, subforem_id: @subforem_id)
      @assignment.with_lock do
        now = Time.current
        @config = FeedConfig.active.find_by(id: @assignment.feed_config_id)
        if @config.nil? || @assignment.expires_at.nil? || @assignment.expires_at <= now
          @config = select_active_config
          @assignment.update!(feed_config: @config, expires_at: Time.current + hours.hours, last_rewarded_at: nil)
        end
      end
      @config
    end

    def visit_token(host:)
      @assignment&.visit_token(host: host)
    end

    private

    def select_active_config
      loop do
        candidate = select_random_config
        # Archival takes the same row lock. Recheck active status after waiting,
        # and hold the lock until the assignment commits.
        config = FeedConfig.active.lock.find_by(id: candidate.id)
        return config if config
      end
    end

    def select_random_config
      FeedConfig.select_for_feed(user: @user, context_type: FeedEvent::CONTEXT_TYPE_HOME)
    end
  end
end
