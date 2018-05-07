class CreateBadgeAchievements < ActiveRecord::Migration[5.1]
  def change
    create_table :badge_achievements do |t|
      t.references :user, foreign_key: true, null: false
      t.integer :rewarder_id
      t.references :badge, foreign_key: true, null: false

      t.timestamps
    end

    add_index :badge_achievements, [:user_id, :badge_id]
  end
end
