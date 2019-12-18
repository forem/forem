class AddHomeScreenToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :featured, :boolean, default: false
  end
end
