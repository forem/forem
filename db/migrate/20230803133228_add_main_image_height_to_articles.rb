class AddMainImageHeightToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :main_image_height, :integer, default: 420
  end
end
