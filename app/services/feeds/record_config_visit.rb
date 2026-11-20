module Feeds
  class RecordConfigVisit
    UUID_PATTERN = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i

    def self.call(...)
      new(...).call
    end

    def self.valid_uuid?(value)
      return false unless value.is_a?(String)

      native = ForemNative.valid_uuid(value)
      native.nil? ? UUID_PATTERN.match?(value) : native
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

      if @edge_token
        record_edge_token_visit
      else
        assignment = FeedConfigAssignment.find_by(
          id: @data["assignment_id"], user_id: @user_id, subforem_id: @data["subforem_id"],
        )
        return unless assignment

        assignment.with_lock do
          @now = Time.current
          next unless active_assignment?(assignment)

          record_event(assignment)
        end
      end
    rescue ActiveRecord::RecordNotFound
      # A user, subforem, or assignment can disappear between lookup and locking.
      nil
    end

    private

    def valid_payload?
      return false unless @token.is_a?(String) && @token.bytesize <= 4096
      return false unless self.class.valid_uuid?(@event_id)

      if edge_visit_token?
        return false unless FeatureFlag.enabled?(:fastly_edge_feed_mirror) && EdgeFeed::TokenSigner.configured?

        @edge_token = true
        @data = EdgeFeed::TokenSigner.verify_visit_token(@token)
      else
        @edge_token = false
        @data = FeedConfigAssignment.visit_verifier.verified(@token, purpose: :feed_config_visit)
      end

      @data.is_a?(Hash) && @data["user_id"] == @user_id && @data["host"] == @host &&
        @data["subforem_id"] == @subforem_id
    end

    def edge_visit_token?
      @token.start_with?("#{EdgeFeed::TokenSigner::VISIT_TOKEN_PREFIX}.")
    end

    def record_edge_token_visit
      expires_at = @data["expires_at"]
      return unless expires_at.is_a?(Time) && enabled?(@subforem_id)

      FeedConfigAssignment.transaction(requires_new: true) do
        lock_edge_assignment_scope
        @now = Time.current
        next unless expires_at > @now && FeedConfig.active.exists?(id: @data["feed_config_id"])

        assignment = find_or_sync_edge_assignment(expires_at)
        record_event(assignment)
      end
    end

    def lock_edge_assignment_scope
      key = Digest::SHA256.digest("feed_config_assignment:#{@user_id}:#{@subforem_id}").unpack1("q>")
      FeedConfigAssignment.connection.execute("SELECT pg_advisory_xact_lock(#{key})")
    end

    def find_or_sync_edge_assignment(expires_at)
      assignment = FeedConfigAssignment.lock.find_by(user_id: @user_id, subforem_id: @subforem_id)
      if assignment.nil?
        FeedConfigAssignment.create!(
          user_id: @user_id,
          subforem_id: @subforem_id,
          feed_config_id: @data["feed_config_id"],
          expires_at: expires_at,
          last_rewarded_at: nil,
          repeat_visits_count: 0,
        )
      elsif assignment.feed_config_id == @data["feed_config_id"] && assignment.expires_at.to_i == expires_at.to_i
        assignment
      else
        assignment.update!(
          feed_config_id: @data["feed_config_id"],
          expires_at: expires_at,
          last_rewarded_at: nil,
          repeat_visits_count: 0,
        )
        assignment
      end
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
