class AddIncludeBadgeDescriptionInEmail < ActiveRecord::Migration[7.0]
  def change
    add_column :badge_achievements, :include_default_description, :boolean, default: true, null: false
  end
end
