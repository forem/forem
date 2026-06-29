class LeaderboardsController < ApplicationController
  # No authorization required for entirely public controller

  def index
    exclude_ids = [Settings::General.mascot_user_id, Settings::Community.staff_user_id].compact
    query = User.registered
                .without_role(:suspended)
                .without_role(:spam)
                .where("badge_achievements_count > 0")

    query = query.where.not(id: exclude_ids) if exclude_ids.any?

    @users = query.order(badge_achievements_count: :desc)
                  .limit(100)
                  .includes(badge_achievements: :badge)
  end
end
