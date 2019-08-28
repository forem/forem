class AddBadgeIdToTags < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :badge_id, :integer
    add_column :tags, :category, :string, default: "uncategorized", null: false
  end
end
