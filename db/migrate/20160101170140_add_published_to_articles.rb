class AddPublishedToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :published, :boolean, default:false
    add_column :articles, :password, :string
  end
end
