class AddCachedTagListToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :cached_tag_list, :string
  end
end
