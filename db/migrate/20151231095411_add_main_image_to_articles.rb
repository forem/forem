class AddMainImageToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :main_image, :string
  end
end
