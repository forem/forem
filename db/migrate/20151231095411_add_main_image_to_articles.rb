class AddMainImageToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :main_image, :string
  end
end
