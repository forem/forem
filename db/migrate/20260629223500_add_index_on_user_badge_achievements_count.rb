class AddIndexOnUserBadgeAchievementsCount < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :users, :badge_achievements_count,
              where: "registered = TRUE AND score >= 0 AND badge_achievements_count > 0",
              name: "index_users_on_badge_achievements_count_leaderboard",
              algorithm: :concurrently
  end
end
