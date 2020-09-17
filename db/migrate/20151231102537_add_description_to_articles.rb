class AddDescriptionToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :description, :string
  end
end
