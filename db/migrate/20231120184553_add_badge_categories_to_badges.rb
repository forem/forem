class AddBadgeCategoriesToBadges < ActiveRecord::Migration[7.0]
  def change
    add_column :badges, :badge_category_id, :bigint, null: true
  end
end
