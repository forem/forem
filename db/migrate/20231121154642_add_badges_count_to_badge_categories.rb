class AddBadgesCountToBadgeCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :badge_categories, :badges_count, :integer, default: 0
  end
end
