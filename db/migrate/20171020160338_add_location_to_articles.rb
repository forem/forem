class AddLocationToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :lat, :decimal, precision: 10, scale: 6
    add_column :articles, :long, :decimal, precision: 10, scale: 6
  end
end
