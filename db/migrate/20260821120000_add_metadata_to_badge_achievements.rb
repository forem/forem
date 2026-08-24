class AddMetadataToBadgeAchievements < ActiveRecord::Migration[8.0]
  def change
    add_column :badge_achievements, :metadata, :jsonb, default: {}, null: false
  end
end
