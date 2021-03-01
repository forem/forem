class ValidateMissingForeignKeysToBackupDataBadgeAchievementsBanishedUsersBufferUpdates < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :badge_achievements, :users, column: :rewarder_id

    validate_foreign_key :banished_users, :users, column: :banished_by_id

    validate_foreign_key :buffer_updates, :users, column: :approver_user_id
    validate_foreign_key :buffer_updates, :users, column: :composer_user_id
    validate_foreign_key :buffer_updates, :tags, column: :tag_id
  end
end
