class AddBadgeAchievementsCountToUsers < ActiveRecord::Migration[5.1]
  def self.up
    add_column :users, :badge_achievements_count, :integer, null: false, default: 0
    add_column :users, :email_badge_notifications, :boolean, default: true
  end

  def self.down
    remove_column :users, :badge_achievements_count
    remove_column :users, :email_badge_notifications
  end
end
