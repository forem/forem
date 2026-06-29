class LeaderboardsController < ApplicationController
  # No authorization required for entirely public controller

  def index
    set_cache_control_headers(60)
    exclude_ids = [Settings::General.mascot_user_id, Settings::Community.staff_user_id].compact
    cache_key = ["leaderboard/users-v2", exclude_ids.sort].join("/")
    @users = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      query = User.registered
                  .where("score >= 0")
                  .where("badge_achievements_count > 0")

      query = query.where.not(id: exclude_ids) if exclude_ids.any?

      query.order(badge_achievements_count: :desc)
            .limit(100)
            .includes(badge_achievements: :badge)
            .to_a
    end
  end
end
