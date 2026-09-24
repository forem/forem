class AddEarnedFavoritesCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :earned_favorites_count, :integer, default: 0, null: false
  end
end
