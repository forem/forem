class AddFavoritedByUserIdToArticles < ActiveRecord::Migration[8.0]
  def up
    add_column :articles, :favorited_by_user_id, :bigint
    add_foreign_key :articles, :users, column: :favorited_by_user_id, on_delete: :nullify, validate: false
    add_column :articles, :favorited_at, :datetime
  end

  def down
    safety_assured do
      remove_foreign_key :articles, :users, column: :favorited_by_user_id
      remove_column :articles, :favorited_by_user_id, :bigint
      remove_column :articles, :favorited_at, :datetime
    end
  end
end
