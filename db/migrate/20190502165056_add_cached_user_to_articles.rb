class AddCachedUserToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :cached_user, :text
    add_column :articles, :cached_organization, :text
  end
end
