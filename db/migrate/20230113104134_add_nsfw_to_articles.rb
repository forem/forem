class AddNsfwToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :nsfw, :boolean, default:false
  end
end
