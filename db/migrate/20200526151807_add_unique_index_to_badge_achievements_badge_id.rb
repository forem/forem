class AddUniqueIndexToBadgeAchievementsBadgeId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :badge_achievements, %i[badge_id user_id], unique: true, algorithm: :concurrently
  end
end
