module CommunityLeaders
  # Revokes the community leader role from leaders who have been inactive for
  # longer than a given duration or the configured number of days.
  class PruneInactive
    Result = Struct.new(:success?, :pruned_count, keyword_init: true)

    MINIMUM_WINDOW_DAYS = 30

    def self.call(...)
      new(...).call
    end

    # @param inactive_for [ActiveSupport::Duration] optional window override
    def initialize(inactive_for: nil)
      @inactive_for = inactive_for
    end

    def call
      pruned = 0

      leaders.each do |leader|
        next if last_active_at(leader) > threshold

        CommunityLeaders::Remove.call(leader)
        pruned += 1
      end

      Result.new(success?: true, pruned_count: pruned)
    end

    private

    attr_reader :inactive_for

    def leaders
      User.community_leaders
        .select("users.*, MAX(users_roles.created_at) AS leader_since")
        .group("users.id")
    end

    def threshold
      @threshold ||= (inactive_for || configured_window).ago
    end

    def configured_window
      # MINIMUM_WINDOW_DAYS is set to guard against revocation en masse if the
      # period setting is set too low by accident
      [
        Settings::UserExperience.community_leader_inactivity_days.to_i,
        MINIMUM_WINDOW_DAYS,
      ].max.days
    end

    # Returns the most recent of available indicators including appointment date
    def last_active_at(user)
      timestamps = User::ACTIVITY_TIMESTAMP_KEYS.filter_map { |key| user.public_send(key) }
      (timestamps << leader_since(user)).max
    end

    def leader_since(user)
      value = user[:leader_since]
      value.is_a?(String) ? Time.zone.parse(value) : value
    end
  end
end
