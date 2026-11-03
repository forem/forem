module Feeds
  class RecordConfigVisit
    UUID_PATTERN = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i

    def self.call(...)
      new(...).call
    end

    def initialize(token:, event_id:, user_id:, host:,
                   subforem_id: RequestStore.store[:subforem_id] || RequestStore.store[:default_subforem_id])
      @token = token
      @event_id = event_id
      @user_id = user_id
      @host = host
      @subforem_id = subforem_id
    end

    def call
      return unless valid_payload?

      assignment = FeedConfigAssignment.find_by(
        id: @data["assignment_id"], user_id: @user_id, subforem_id: @data["subforem_id"],
      )
      return unless assignment

      assignment.with_lock do
        @now = Time.current
        next unless active_assignment?(assignment)

        record_event(assignment)
      end
    rescue ActiveRecord::RecordNotFound
      # A user, subforem, or assignment can disappear between lookup and locking.
      nil
    end

    private

    def valid_payload?
      return false unless @token.is_a?(String) && @token.bytesize <= 4096
      return false unless @event_id.is_a?(String) && UUID_PATTERN.match?(@event_id)

      @data = FeedConfigAssignment.visit_verifier.verified(@token, purpose: :feed_config_visit)
      @data.is_a?(Hash) && @data["user_id"] == @user_id && @data["host"] == @host &&
        @data["subforem_id"] == @subforem_id
    end

    def active_assignment?(assignment)
      assignment.feed_config_id == @data["feed_config_id"] && assignment.expires_at.present? &&
        assignment.expires_at > @now && assignment.expires_at.utc.iso8601(6) == @data["expires_at"] &&
        enabled?(assignment.subforem_id) && FeedConfig.active.exists?(id: assignment.feed_config_id)
    end

    def enabled?(subforem_id)
      Settings::UserExperience.feed_config_sticky_hours(subforem_id: subforem_id).positive? &&
        Settings::UserExperience.feed_config_sticky_percentage(subforem_id: subforem_id).positive?
    end

    def record_event(assignment)
      return if assignment.repeat_visits_count >= FeedConfigAssignment::MAX_REPEAT_VISITS

      interval = Settings::UserExperience.feed_config_repeat_visit_minutes(
        subforem_id: assignment.subforem_id,
      ).minutes
      # Keep suppressed IDs too: a retry must never become a new visit after
      # the cooldown. Receipt, cooldown, counter, and score commit together.
      inserted = FeedEventReceipt.insert_all([{ id: @event_id }], unique_by: :id, returning: %w[id]).any?
      if inserted && assignment.last_rewarded_at.nil?
        assignment.update!(last_rewarded_at: @now)
      elsif inserted && assignment.last_rewarded_at <= @now - interval
        return if FeedConfig.record_repeat_visit(assignment.feed_config_id).zero?

        assignment.update!(
          last_rewarded_at: @now,
          repeat_visits_count: assignment.repeat_visits_count + 1,
        )
      end
      assignment.last_rewarded_at + interval if assignment.last_rewarded_at
    end
  end
end
