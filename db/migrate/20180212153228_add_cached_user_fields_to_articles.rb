class AddCachedUserFieldsToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :path, :string
    add_column :articles, :cached_user_name, :string
    add_column :articles, :cached_user_username, :string
  end
end
