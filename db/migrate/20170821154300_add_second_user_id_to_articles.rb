class AddSecondUserIdToArticles < ActiveRecord::Migration[5.0]
  def change
    add_column :articles, :second_user_id, :integer
    add_column :articles, :third_user_id, :integer
  end
end
