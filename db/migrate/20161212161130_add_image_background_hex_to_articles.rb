class AddImageBackgroundHexToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :main_image_background_hex_color, :string, default: "#dddddd"
  end
end
