module Feeds
  # Selects a configuration for a first-page home feed, including preloads.
  # Only an authenticated visibility acknowledgement can earn return credit.
  class StickyConfig
    def initialize(user:, subforem_id: RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id])
      @user = user
      @subforem_id = subforem_id
    end

    def select
      hours = Settings::UserExperience.feed_config_sticky_hours(subforem_id: @subforem_id)
      percentage = Settings::UserExperience.feed_config_sticky_percentage(subforem_id: @subforem_id)
      return select_random_config unless hours.positive? && rand(100) < percentage

      @assignment = FeedConfigAssignment.find_by(user: @user, subforem_id: @subforem_id)
      @config = active_assigned_config(Time.current)
      return @config if @config

      FeedConfigAssignment.transaction(requires_new: true) do
        lock_assignment_scope
        @assignment = FeedConfigAssignment.lock.find_by(user: @user, subforem_id: @subforem_id)
        now = Time.current
        @config = active_assigned_config(now)
        if @config.nil?
          @config = select_active_config
          expires_at = Time.current + hours.hours
          if @assignment
            @assignment.update!(
              feed_config: @config,
              expires_at: expires_at,
              last_rewarded_at: nil,
              repeat_visits_count: 0,
            )
          else
            @assignment = FeedConfigAssignment.create!(
              user: @user,
              subforem_id: @subforem_id,
              feed_config: @config,
              expires_at: expires_at,
              last_rewarded_at: nil,
              repeat_visits_count: 0,
            )
          end
        end
      end
      @config
    end

    def visit_token(host:)
      @assignment&.visit_token(host: host)
    end

    private

    def active_assigned_config(now)
      return unless @assignment&.feed_config_id && @assignment&.expires_at && @assignment.expires_at > now

      FeedConfig.active.find_by(id: @assignment.feed_config_id)
    end

    def lock_assignment_scope
      key = Digest::SHA256.digest("feed_config_assignment:#{@user.id}:#{@subforem_id}").unpack1("q>")
      FeedConfigAssignment.connection.execute("SELECT pg_advisory_xact_lock(#{key})")
    end

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
