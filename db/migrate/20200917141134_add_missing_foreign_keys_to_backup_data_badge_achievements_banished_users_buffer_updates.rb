class AddMissingForeignKeysToBackupDataBadgeAchievementsBanishedUsersBufferUpdates < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :badge_achievements, :users, column: :rewarder_id, on_delete: :nullify, validate: false

    add_foreign_key :banished_users, :users, column: :banished_by_id, on_delete: :nullify, validate: false

    add_foreign_key :buffer_updates, :users, column: :approver_user_id, on_delete: :nullify, validate: false
    add_foreign_key :buffer_updates, :users, column: :composer_user_id, on_delete: :nullify, validate: false
    add_foreign_key :buffer_updates, :tags, column: :tag_id, on_delete: :nullify, validate: false
  end
end
