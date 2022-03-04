class AddPositiveColumnToReactions < ActiveRecord::Migration[5.0]
  def change
    add_column :articles, :positive_reactions_count, :integer, null: false, default: 0
    add_column :comments, :positive_reactions_count, :integer, null: false, default: 0
  end
end
