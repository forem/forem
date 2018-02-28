class AddPublishedToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :published, :boolean, default:false
    add_column :articles, :password, :string
  end
end
